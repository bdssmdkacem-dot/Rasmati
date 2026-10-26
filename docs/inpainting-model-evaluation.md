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


## Licensing and Android compatibility audit (2026-10-26)

### License status: source code is not enough

- The upstream `advimman/lama` repository declares Apache-2.0 for its code. Its README distributes the `big-lama` checkpoint separately through a third-party Hugging Face mirror / Google Drive path.
- Recent upstream issues explicitly ask whether the separately distributed pretrained weights are covered by Apache-2.0; the repository's code license alone does not settle that question. A third-party model card declaring Apache-2.0 is useful provenance but is not a substitute for a clear license grant from the rights holder for the exact checkpoint.
- **Commercial redistribution gate: unresolved. Do not bundle or redistribute the upstream `big-lama` weights in a commercial Rasmati APK until the exact checkpoint's license and provenance are documented from an authoritative source.** Keep the model out of the app package while this is unresolved. If the rights holder does not clarify, select a model with an explicit, auditable license for both code and weights, or obtain legal review/permission.

Sources checked:
- Upstream project and separate checkpoint download instructions: https://github.com/advimman/lama
- Open licensing clarification requests for the pretrained weights: https://github.com/advimman/lama/issues/365 and https://github.com/advimman/lama/issues/368
- ONNX export mirror claiming Apache-2.0 for its export: https://huggingface.co/edgetools/lama (third-party claim; not treated as authoritative rights-holder confirmation)

### Android runtime path

- Flutter package candidate: `flutter_onnxruntime`, which wraps ONNX Runtime and documents Android support; the package page notes that versions at or above 1.5.1 address Android 16 KB page-size compatibility. This is a candidate to prototype, not yet a dependency in Rasmati.
- ONNX Runtime documents Android CPU inference and NNAPI acceleration. NNAPI requires Android 8.1+ and is recommended on Android 9+; operator support and partitioning can reduce acceleration, so CPU must remain a correctness fallback.
- A LaMa ONNX export surfaced in a third-party model card uses fixed `[1,3,512,512]` RGB image and `[1,1,512,512]` mask tensors, with `1 = hole` mask polarity and an output that must be composited by the caller. These assumptions must be verified against the exact artifact and checksum before implementing preprocessing.

Sources:
- Flutter ONNX Runtime package: https://pub.dev/packages/flutter_onnxruntime
- ONNX Runtime mobile deployment: https://onnxruntime.ai/docs/tutorials/mobile/
- ONNX Runtime NNAPI requirements and supported operators: https://onnxruntime.ai/docs/execution-providers/NNAPI-ExecutionProvider.html
- Third-party LaMa ONNX export details: https://huggingface.co/edgetools/lama

### Prototype entry criteria

1. Resolve model-weight redistribution rights before shipping weights; no legal assumption based solely on the code repository license.
2. Select and pin the exact ONNX file, record source URL, license evidence, SHA-256, file size, input/output names and tensor shapes.
3. Add the runtime only on a prototype branch; confirm Android ABI coverage and 16 KB page-size compatibility in the produced APK.
4. Validate tensor normalization and mask polarity with synthetic tests before evaluating real drawings.
5. Measure APK size, cold/warm latency, peak memory and failure fallback on the actual target phone. Do not enable NNAPI by default until parity and stability are demonstrated.

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
