#!/usr/bin/env python3
"""Offline evaluation harness for the pinned LaMa ONNX artifact.

Install locally: python -m pip install numpy Pillow onnxruntime
No network calls are made by this script. It accepts a real drawing and a
binary mask (white = removed region), or creates synthetic line/face/limb
fixtures with known ground truth. Outputs are saved locally only.
"""
from __future__ import annotations

import argparse
import hashlib
import json
import time
try:
    import resource
except ImportError:  # Windows has no resource module.
    resource = None
from pathlib import Path

import numpy as np
import onnxruntime as ort
from PIL import Image, ImageDraw

EXPECTED_SHA256 = "1faef5301d78db7dda502fe59966957ec4b79dd64e16f03ed96913c7a4eb68d6"
SIZE = 512


def sha256(path: Path) -> str:
    digest = hashlib.sha256()
    with path.open("rb") as handle:
        for chunk in iter(lambda: handle.read(1024 * 1024), b""):
            digest.update(chunk)
    return digest.hexdigest()


def fixtures() -> dict[str, tuple[Image.Image, Image.Image]]:
    cases: dict[str, tuple[Image.Image, Image.Image]] = {}

    # Thin line: a known vertical contour crossing the missing strip.
    image = Image.new("RGB", (SIZE, SIZE), "white")
    draw = ImageDraw.Draw(image)
    draw.line((256, 35, 256, 477), fill="black", width=5)
    draw.line((80, 256, 432, 256), fill=(45, 100, 210), width=3)
    mask = Image.new("L", (SIZE, SIZE), 0)
    ImageDraw.Draw(mask).rectangle((244, 210, 268, 300), fill=255)
    cases["thin_lines"] = (image, mask)

    # Face: eyes, mouth and face outline with a mask crossing one cheek.
    image = Image.new("RGB", (SIZE, SIZE), "white")
    draw = ImageDraw.Draw(image)
    draw.ellipse((130, 65, 382, 370), outline=(45, 45, 45), width=7)
    draw.ellipse((190, 160, 218, 190), fill="black")
    draw.ellipse((294, 160, 322, 190), fill="black")
    draw.arc((200, 190, 312, 305), start=10, end=170, fill=(180, 40, 55), width=6)
    draw.line((256, 195, 244, 238, 260, 240), fill=(50, 50, 50), width=4)
    mask = Image.new("L", (SIZE, SIZE), 0)
    ImageDraw.Draw(mask).rectangle((230, 190, 275, 270), fill=255)
    cases["face_details"] = (image, mask)

    # Limbs: simple child-like torso and crossing arms/legs.
    image = Image.new("RGB", (SIZE, SIZE), "white")
    draw = ImageDraw.Draw(image)
    draw.ellipse((218, 35, 294, 111), outline="black", width=5)
    draw.line((256, 112, 256, 285), fill=(30, 120, 65), width=24)
    draw.line((250, 145, 155, 210), fill=(30, 120, 65), width=17)
    draw.line((262, 145, 360, 205), fill=(30, 120, 65), width=17)
    draw.line((256, 280, 200, 430), fill=(30, 70, 190), width=19)
    draw.line((256, 280, 320, 430), fill=(30, 70, 190), width=19)
    mask = Image.new("L", (SIZE, SIZE), 0)
    ImageDraw.Draw(mask).rectangle((230, 180, 283, 245), fill=255)
    cases["limb_overlap"] = (image, mask)
    return cases


def model_contract(session: ort.InferenceSession) -> tuple[str, str, str]:
    inputs = {item.name: item for item in session.get_inputs()}
    outputs = {item.name: item for item in session.get_outputs()}
    if "image" not in inputs or "mask" not in inputs or "output" not in outputs:
        raise RuntimeError(
            f"Unexpected model tensor names; inputs={list(inputs)}, outputs={list(outputs)}"
        )
    expected_image = [1, 3, SIZE, SIZE]
    expected_mask = [1, 1, SIZE, SIZE]
    for name, expected in (("image", expected_image), ("mask", expected_mask)):
        shape = inputs[name].shape
        if len(shape) != 4 or any(isinstance(a, int) and a != b for a, b in zip(shape, expected)):
            raise RuntimeError(f"Unexpected {name} input shape {shape}; expected {expected}")
    output_shape = outputs["output"].shape
    if len(output_shape) != 4 or any(
        isinstance(a, int) and a != b
        for a, b in zip(output_shape, [1, 3, SIZE, SIZE])
    ):
        raise RuntimeError(f"Unexpected output shape {output_shape}")
    return "image", "mask", "output"


def run_case(session, names, original: Image.Image, mask_image: Image.Image, out_dir: Path, name: str):
    image_name, mask_name, output_name = names
    original = original.convert("RGB").resize((SIZE, SIZE), Image.Resampling.LANCZOS)
    mask_image = mask_image.convert("L").resize((SIZE, SIZE), Image.Resampling.NEAREST)
    truth = np.asarray(original, dtype=np.uint8).copy()
    mask = (np.asarray(mask_image, dtype=np.uint8) >= 128)
    if not mask.any():
        raise ValueError(f"{name}: mask is empty")

    model_image = truth.copy()
    model_image[mask] = 0
    nchw = np.transpose(model_image.astype(np.float32) / 255.0, (2, 0, 1))[None, ...]
    mask_tensor = mask.astype(np.float32)[None, None, ...]

    start = time.perf_counter()
    output = session.run([output_name], {image_name: nchw, mask_name: mask_tensor})[0]
    elapsed_ms = (time.perf_counter() - start) * 1000
    output = np.asarray(output, dtype=np.float32)
    if output.shape != (1, 3, SIZE, SIZE):
        raise RuntimeError(f"{name}: unexpected output tensor shape {output.shape}")
    if not np.isfinite(output).all():
        raise RuntimeError(f"{name}: output contains NaN or infinity")
    if float(output.max()) <= 1.5:
        raise RuntimeError(
            f"{name}: output looks normalized to [0,1], but the pinned contract expects [0,255]; "
            "stop and resolve scaling rather than silently creating a dark result"
        )
    rgb = np.transpose(np.clip(output[0], 0, 255), (1, 2, 0)).astype(np.uint8)
    composite = truth.copy()
    composite[mask] = rgb[mask]

    diff = composite.astype(np.float32) - truth.astype(np.float32)
    masked_diff = diff[mask]
    mae = float(np.abs(masked_diff).mean()) if masked_diff.size else 0.0
    # Preserve every pixel outside the mask by construction.
    outside_unchanged = bool(np.array_equal(composite[~mask], truth[~mask]))

    out_dir.mkdir(parents=True, exist_ok=True)
    original.save(out_dir / f"{name}_original.png")
    mask_image.save(out_dir / f"{name}_mask.png")
    Image.fromarray(composite, "RGB").save(out_dir / f"{name}_repaired.png")
    side_by_side = Image.new("RGB", (SIZE * 3, SIZE), "white")
    side_by_side.paste(original, (0, 0))
    side_by_side.paste(mask_image.convert("RGB"), (SIZE, 0))
    side_by_side.paste(Image.fromarray(composite, "RGB"), (SIZE * 2, 0))
    side_by_side.save(out_dir / f"{name}_comparison.png")
    return {
        "case": name,
        "latency_ms": round(elapsed_ms, 2),
        "masked_mae_vs_known_ground_truth": round(mae, 3),
        "masked_pixels": int(mask.sum()),
        "outside_mask_exactly_preserved": outside_unchanged,
        "output_min": float(output.min()),
        "output_max": float(output.max()),
    }


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("--model", type=Path, default=Path(".local_models/lama_fp32.onnx"))
    parser.add_argument("--output-dir", type=Path, default=Path("build/lama-evaluation"))
    parser.add_argument("--image", type=Path, help="Optional real drawing image")
    parser.add_argument("--mask", type=Path, help="Required with --image; white pixels are removed")
    parser.add_argument("--expected-sha256", default=EXPECTED_SHA256)
    args = parser.parse_args()

    if not args.model.is_file():
        raise SystemExit(f"Model not found: {args.model}. Run bash tool/fetch_lama_model.sh first.")
    actual_sha = sha256(args.model)
    if actual_sha != args.expected_sha256:
        raise SystemExit(f"SHA-256 mismatch: expected {args.expected_sha256}, got {actual_sha}")
    if bool(args.image) != bool(args.mask):
        raise SystemExit("--image and --mask must be supplied together.")
    if args.image and (not args.image.is_file() or not args.mask.is_file()):
        raise SystemExit("The real drawing or mask path does not exist.")

    options = ort.SessionOptions()
    options.intra_op_num_threads = 2
    options.inter_op_num_threads = 1
    session = ort.InferenceSession(str(args.model), sess_options=options, providers=["CPUExecutionProvider"])
    names = model_contract(session)

    cases = fixtures()
    if args.image:
        cases["provided_drawing"] = (Image.open(args.image), Image.open(args.mask))
    results = []
    for name, (image, mask) in cases.items():
        results.append(run_case(session, names, image, mask, args.output_dir, name))

    report = {
        "model_path": str(args.model),
        "sha256": actual_sha,
        "input_names": [x.name for x in session.get_inputs()],
        "input_shapes": {x.name: x.shape for x in session.get_inputs()},
        "output_names": [x.name for x in session.get_outputs()],
        "output_shapes": {x.name: x.shape for x in session.get_outputs()},
        "peak_rss_process_high_water_mark": (resource.getrusage(resource.RUSAGE_SELF).ru_maxrss if resource else None),
        "cases": results,
        "warning": "Synthetic fixtures are not a substitute for visual review of permissioned real drawings or on-device Android measurements.",
    }
    args.output_dir.mkdir(parents=True, exist_ok=True)
    (args.output_dir / "report.json").write_text(json.dumps(report, indent=2), encoding="utf-8")
    print(json.dumps(report, indent=2))


if __name__ == "__main__":
    main()
