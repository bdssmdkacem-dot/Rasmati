# Rasmati inpainting model evaluation

Date: 2026-10-26  
Status: evaluation plan; no neural inpainting model is integrated or accepted yet.

## Product requirement

When the rig editor removes pixels that belong to a moving part, Rasmati must reconstruct the hidden background well enough that motion does not expose transparent holes, duplicated limbs, or broken line art. This is especially difficult for children’s drawings: the hidden region can contain unique anatomy and intentional outlines, so plausible-looking photographic texture is not sufficient.

**Privacy requirement:** all default repair inference runs on-device. No drawing, crop, mask, embedding, or telemetry containing artwork may be sent to a remote service. A future remote option would require a separate, explicit, informed opt-in before any upload; it is not part of the current implementation plan.

## Candidate assessment

| Candidate | Strengths | Risks for Rasmati | Decision |
| --- | --- | --- | --- |
| Existing exemplar-based patch repair | Small, deterministic, no model download, no network | Copies patterns from nearby source pixels; cannot invent missing anatomy; may leave seams | Keep as local fallback for small cutouts |
| LaMa / big-lama, locally packaged or converted to ONNX | Genuine learned inpainting; known open-source research implementation; can plausibly synthesize larger missing regions | Model conversion/runtime integration and licensing need verification; may hallucinate or smooth child-drawn outlines; memory and latency must be measured on target devices | First neural candidate for a controlled prototype, not yet approved for production |
| Qualcomm LaMa-Dilated | Published mobile deployment candidate; Qualcomm model card lists 512×512 input and a 174 MB float model, with reported mobile measurements on selected Snapdragon devices | Its stated checkpoint is Dilated CelebAHQ, so its domain may be poorly matched to cartoon/child line art; published device metrics do not predict performance on every Android phone | Benchmark only if target chipset/runtime is supported; do not select by speed claims alone |
| Hosted inpainting API | Can offer high-quality inference without bundling a large model | Sends private children’s drawings off-device and depends on connectivity, service terms, and consent | Excluded from default workflow; any future use must be separate opt-in |

Reference material:
- LaMa paper/project: https://github.com/saic-mdal/lama
- Qualcomm LaMa-Dilated model card and mobile deployment details: https://huggingface.co/qualcomm/LaMa-Dilated
- Qualcomm AI Hub model entry: https://aihub.qualcomm.com/mobile/models/lama_dilated

## Proposed architecture

1. Define a LocalInpaintingEngine boundary in Dart and a result type that carries output image, engine identifier, elapsed time, input dimensions, and a safe failure reason. Never include image pixels or file paths in telemetry.
2. Keep the current patch-based repair as a deterministic fallback for tiny holes and as a fallback when the model is absent, unsupported, or out of memory.
3. Prototype a neural engine with a pinned, checksum-verified model artifact. Prefer a supported on-device runtime such as ONNX Runtime for Android only after confirming ABI, package size, runtime compatibility, model license, and redistribution rights. No automatic model download should run without clear user action.
4. Execute inference on an isolated copy of the source. Feed the model a crop and mask; composite only the pixels in the removed region back into the saved base. Preserve original source pixels and unrelated transparent pixels exactly.
5. Add resource controls: image-size cap, crop padding, cancellation, progress, memory/error handling, and fallback when the device cannot run the model.
6. Add a preview comparison (original cutout vs repaired result), allow undo/manual correction, and do not auto-accept a neural result.
7. Keep inference fully offline by default. If a remote engine is ever proposed, make it a separate disabled-by-default feature with a plain-language consent screen immediately before upload, explicit image scope, and a no-upload cancellation path.

## Evaluation dataset and acceptance gates

Create a small, permissioned, local test set covering at least:
- flat-color cartoon body with thick outlines;
- thin black lines crossing the removed region;
- face/eyes/mouth close to the cutout;
- limbs crossing the torso and overlapping clothes;
- textured/color-pencil shading;
- large missing region with no similar source patch;
- irregular transparent background and edge-of-canvas masks.

For each image, keep the original and create ground-truth masks by hiding known pixels. Compare the repaired region to the original ground truth. Report:
- visual review by category (outline continuity, face/limb correctness, seams, repeated patterns);
- masked-region MAE/PSNR or SSIM as secondary metrics, not as sole acceptance;
- cold/warm latency, peak memory, model size, battery/thermal behavior on the actual target Android phone;
- exact preservation of pixels outside the mask and original source asset;
- fallback correctness when inference fails or is cancelled.

**Release gates:** flutter analyze, flutter test, debug APK build, reproducible model checksum/license audit, passing unit/integration tests, saved visual regression artifacts for the drawing set, and physical Android testing. Wave/walk/nod must show no exposed holes, duplicate/ghost limbs, or unacceptable seams on the approved drawings. Do not merge PR #1 until these gates pass.

## Current status

- The code currently uses classical exemplar-based inpainting; it is not yet connected to a learned neural model.
- Model choice remains provisional until the prototype is measured on Rasmati's target phone and child-drawing dataset.
- CI for the current branch must pass independently; prior green runs predate the latest inpainting changes.
- Physical-device and real-artwork visual acceptance have not been recorded.
