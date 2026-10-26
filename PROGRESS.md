# Development Progress — Rasmati

## 2026-10-26 rigging validation pass

- Issue #2: [Rebuild character rigging around filled masks and hidden-pixel repair](https://github.com/bdssmdkacem-dot/Rasmati/issues/2) remains open.
- Added closed filled-polygon masks to `lib/character_part_editor.dart`, retaining the correction brush and full-canvas normalized coordinates.
- Fixed the image-library polygon vertex type after the CI log identified `List<Point<int>>` versus `List<Point>`.
- Added `lib/rig_mask_validation.dart` and `test/rig_mask_validation_test.dart`; checks cover empty/too-small masks, fewer than two usable parts, unknown IDs, negative pixel counts, and valid masks.
- The editor now checks the alpha-pixel count for every part the user attempted to mark before removing source pixels from the base or opening the joint preview.
- README updated with the implementation and known gaps.
- Current CI for code + tests is pending: [run #139](https://github.com/bdssmdkacem-dot/Rasmati/actions/runs/40379585178). Older run #135 failed at static analysis due to the polygon point type; do not cite that run as passing.
- Hidden-pixel reconstruction remains unresolved. No clone/repair workflow has been implemented yet; polygon masks alone cannot restore linework/background hidden behind limbs.
- No real-drawing visual regression or physical Android install/test has been performed in this pass. Keep PR #1 unmerged and issue #2 open.
- Next: wait for current CI; fix any analyzer/test/build failures. Then implement a deliberate hidden-region repair workflow (not a fake auto-fill), add fixture-based visual comparisons for wave/walk/nod, and install the resulting APK on a physical Android device.


Last updated: 2026-10-26

This file is the hand-off record for continuing work in a new chat. Update it after each meaningful change, fix, or verification.

## Product direction and decisions

- Android-first Flutter/Dart app for turning children's paper drawings into animations.
- Preserve the child's original drawing, colors, and linework; do not replace it with generated art.
- Let the user capture a drawing with the camera or choose one from the gallery.
- Prefer local processing and local storage by default; do not upload drawings without clear user consent.
- Long-term goal: accurate background removal/manual correction, independently animatable body parts, and MP4 export.
- Keep the UI Arabic/RTL-first unless the product requirements change.

## Implemented and committed

- Initial Flutter app scaffold and project configuration: pubspec.yaml, analysis_options.yaml, and .gitignore.
- Arabic RTL home screen in lib/main.dart.
- Camera and gallery import using image_picker.
- Initial animation studio with selectable whole-image motion presets and background choices.
- Pause/play control for the preview.
- Smoke test in test/widget_test.dart.
- GitHub Actions workflow in .github/workflows/flutter.yml for dependency resolution, static analysis, tests, and debug APK build/artifact upload.
- Fixed Dart switch-case termination by adding explicit break statements.
- Fixed preview pause behavior so changing motion while paused does not resume playback.
- Fixed CI static-analysis issue by removing unused _mint constant from lib/main.dart.
- Added lib/background_editor.dart: local white-paper edge flood fill, adjustable threshold, transparent checkerboard preview, manual erase/restore strokes, undo/redo, and PNG output.
- Routed camera/gallery selections through the background editor before opening AnimationStudio in lib/main.dart.
- Added image and path_provider dependencies for local pixel processing and temporary PNG output.
- Aligned manual brush coordinates to the actual BoxFit.contain image bounds so strokes map to the drawing rather than the surrounding canvas.
- Added a separate automatic-removal preview action; preview remains local and can be recalculated after changing threshold.
- Established the first Rasmati brand kit: `assets/branding/rasmati_icon.svg`, `rasmati_mark.svg`, `rasmati_foreground.svg`, and a functional icon sheet `rasmati_icons.svg`.
- Added `BRAND_GUIDE.md` with the brand story, color tokens, Arabic/RTL UI rules, icon consistency guidance, and asset workflow.
- Added `lib/branding.dart` with shared color tokens and a Flutter-native `RasmatiMark`; replaced the generic sparkle tile in the home header with the brand mark and applied secondary/tertiary brand colors.
- Configured `flutter_launcher_icons` and updated GitHub Actions to render editable SVG sources to PNG and generate Android launcher resources reproducibly during CI.

## Latest commit

- Background-removal testability commit: `1bfe51551bbb590721c6ae1400fa5f06130ad555` — [Add testable removal helper](https://github.com/bdssmdkacem-dot/Rasmati/commit/1bfe51551bbb590721c6ae1400fa5f06130ad555)
- Regression-test commit: `6d391b3861ed7462c30b86b9c9537df334f064de` — [Add removal tests](https://github.com/bdssmdkacem-dot/Rasmati/commit/6d391b3861ed7462c30b86b9c9537df334f064de)
- Latest editor/import fix commit: `92eee5150bd8bebf2f95c3cfe09ca02fb9aca540` — [Sort imports](https://github.com/bdssmdkacem-dot/Rasmati/commit/92eee5150bd8bebf2f95c3cfe09ca02fb9aca540)
- Prior CI/branding fix: `17f44c9ffee5e74601759d5f72b829532f47fe5f` — [Fix unnecessary const warnings](https://github.com/bdssmdkacem-dot/Rasmati/commit/17f44c9ffee5e74601759d5f72b829532f47fe5f)

## Verification status

- Latest verified CI: [run #29](https://github.com/bdssmdkacem-dot/Rasmati/actions/runs/37854578762) for code commit `17f44c9ffee5e74601759d5f72b829532f47fe5f` — **success**.
- Follow-up CI: [run #30](https://github.com/bdssmdkacem-dot/Rasmati/actions/runs/37854592514) for hand-off update commit `49b7d2f0d60b195a43ee5a19f87dcecb971dcf8a` — **success**.
- Both successful runs completed `flutter create --platforms=android .`, SVG-to-PNG rendering, `flutter pub get`, `dart run flutter_launcher_icons`, `flutter analyze`, `flutter test`, `flutter build apk --debug`, and APK artifact upload.
- The three `unnecessary_const` infos in `lib/main.dart` were fixed by removing redundant nested `const` keywords. The current CI validates launcher-icon generation and a debug APK build; visual confirmation on a physical Android launcher remains pending.
- Background-editor code compiles and the existing tests pass, but image-quality/device QA on representative drawings is still pending; do not treat automatic removal as production-proven yet.

## Known limitations / not implemented yet

- Motion presets animate the whole image; limbs/body parts are not independently rigged.
- Background removal and manual edge correction are implemented in code, but require CI completion and real-image/device QA before being considered production-ready.
- The new SVG brand sources are committed. CI successfully rendered PNGs, ran `flutter_launcher_icons`, built the debug APK, and uploaded the artifact in runs #29 and #30. Physical-device launcher appearance is still unverified.
- Extracted the edge-connected paper-removal algorithm into `lib/background_removal.dart` so it can be tested independently. `lib/background_editor.dart` now uses the shared helper for both preview and apply paths.
- Added `test/background_removal_test.dart` regression cases for edge-connected white paper, preservation of enclosed white details, source-image immutability, and threshold sensitivity. CI verification for these new tests is pending.
- MP4/video export is not implemented; the current UI marks export as not yet available.
- No commercial release readiness or device QA has been established yet.

## Next steps (in order)

1. Verify the latest CI after extracting background removal and adding regression tests; fix any analyzer/test/build issues.
2. Expand image-quality tests with pale drawing strokes and non-white paper samples; test manually on representative child drawings.
3. Inspect the generated launcher icon on a real Android device and confirm adaptive-icon masking/appearance.
3. Introduce explicit editable regions / body-part segmentation and a user-controlled rigging workflow; do not claim automatic rigging is reliable before it is implemented and tested.
4. Implement video export (MP4) and verify on a real Android device.
5. Add regression tests for import, background cleanup, preview controls, editing, and export; verify privacy/storage behavior.
6. Review launcher icon on device, add store icon/screenshots, then assess release signing, permissions, performance, accessibility, and Play Store readiness.

## Continuation rules

After each substantial change:
- Record what changed and why, including the original failure and fix.
- Record touched files and commit SHA.
- Record exact CI/test/build outcome and link; distinguish pending from passing.
- Update known limitations and the next concrete step.
- Never describe an unimplemented feature as working, and do not undo product decisions above without an explicit reason.


## 2026-10-09 quality pass

- Updated `lib/background_removal.dart`: stricter default paper detection and a one-pixel soft alpha edge to reduce hard cutout fringes. This is still edge-connected color removal, not full AI segmentation.
- Updated `test/background_removal_test.dart`: added a regression test for feathered edge pixels and adjusted the threshold test to match the revised sensitivity scale.
- Updated `lib/main.dart`: continuous 1.9-second motion loop; combined lift, bob, sway, tilt, and subtle squash/stretch for bounce, walk, dance, wave, and float. All presets still animate the complete image rather than independent limbs.
- Commits: background helper `6e8b3d452a3ce607182d96ba05ce7d440b14e1b5`; tests `f1ab77a22d3b624a53e7661a379afe312ca6f79a`; motion `ce550fc4d55ce7fb7e18485ef1b1f5341a0b9b27`.
- Verification at the time of the quality-pass commit was pending; this was superseded by the successful CI run recorded below.
- Next: test with real photos on white, cream, colored, and shadowed paper; then design guided character-part segmentation/rigging for genuine limb movement.

- Follow-up static-type safety fix: `8b64a885b92144a8afef05e44f196eaf739ff2de` converts the feathering opacity minimum back to an integer for `Uint8List` assignment.


## 2026-10-09 CI confirmation and next milestone

- Latest workflow run #42 for commit `015bc4b81e0226300ff985ca1f5882cd47c05d47` completed successfully: [Flutter CI run #42](https://github.com/bdssmdkacem-dot/Rasmati/actions/runs/37923846341).
- Workflow run #41 for commit `8b64a885b92144a8afef05e44f196eaf739ff2de` also completed successfully: [Flutter CI run #41](https://github.com/bdssmdkacem-dot/Rasmati/actions/runs/37923839929).
- The successful pipeline runs analysis, tests, debug APK build, and artifact upload. This confirms CI health for the current code; it does not replace visual/device QA of background removal or animation.
- Next implementation milestone: add a guided, editable character-part workflow. Users should be able to mark head, torso, arms, and legs, undo/redo corrections, preview transparent masks, and save the parts locally. Only after masks are validated should the animation studio rig parts around user-correctable pivots.
- Architecture requirement: keep the original drawing untouched; preserve full-canvas alignment for extracted part layers; remove extracted pixels from the base layer to avoid ghosting; keep all processing local. Provide a skip path for drawings that are not characters.
- Acceptance tests: part masks remain aligned to the original image; overlapping strokes have deterministic ownership; undo/redo does not corrupt masks; empty segmentation safely falls back to whole-image animation; CI passes. MP4 export remains a separate milestone.
- Status: planning/design only for the guided part editor at this checkpoint; no independent-limb rigging is claimed implemented yet.


## 2026-10-09 background-removal quality milestone

- Added `removeConnectedColorBackground` in `lib/background_removal.dart`. The user can sample a background color from the drawing and remove only the connected region within an adjustable RGB-distance tolerance; enclosed matching-color details are retained when bounded by a closed outline. A narrow alpha transition is applied at the cutout edge.
- Updated `lib/background_editor.dart` with background-color sampling, a visible sampled-color marker, adjustable color tolerance, orientation-corrected sampling coordinates, and a shared brush compositor so erase/restore strokes appear in the generated preview as well as the final PNG.
- Expanded `test/background_removal_test.dart` with colored-background, enclosed-detail, source-immutability, and tolerance tests.
- Relevant commits: helper `31c3d1a38944b9c9c58f19335ef86d2f8a027f69`; sampled-color tests `20da445e2e6da8d72462e86baf36a477cae21168` (followed by test-scope syntax fix `a2dada741e6501cfb5b1822bdeda074909a45111`); editor integration `87a0214fa5057d208ebc8b22c6166cb797f54fa0`; orientation/type fix `2d01bdaa9dbf44d0717efa5133d5dbf8187d6b5e`; preview brush integration `60cc5b5fc97bc9516e1f7a4ba4cfa7c9bf8ee9a4`.
- Verification status at this update: CI for these commits is pending; do not claim the new implementation passes until Actions confirms analyze, tests, and APK build.
- Limitations: sampled-color flood fill is not an AI segmentation model; it works best for connected, relatively uniform backgrounds. High tolerance can remove similar-colored parts of the drawing. Shadows/gradients and hair-thin strokes still need user correction. Keep original file unchanged and use manual erase/restore for final cleanup.
- Next: verify CI and fix any failures; inspect the full editor workflow on device, especially preview after sampling a colored region, tolerance changes, undo/redo, brush visibility, and portrait EXIF orientation. Continue background-removal quality work until those checks pass; only then start body-part motion work.


## 2026-10-09 follow-up: continuous manual correction strokes

- Confirmed Flutter CI run #50 succeeded for the sampled-color background-removal milestone: [run #50](https://github.com/bdssmdkacem-dot/Rasmati/actions/runs/37925432129). The workflow completed analysis, tests, and debug APK build; this is code/CI verification, not proof of real-photo quality on a physical phone.
- Fixed a practical manual-cleanup issue in `lib/background_editor.dart`: a fast finger drag can produce sparse pointer events, so applying only a brush stamp at each event could leave transparent/opaque gaps. The compositor now interpolates between points and stamps at short intervals, for continuous erase/restore strokes in both preview and final PNG.
- Code commit: `bbbff925ca0b5cd9b89a75c80d3db39dcbe3ca73` — Interpolate background correction brush strokes.
- Verification for this follow-up commit: pending its own CI run; do not infer that it has passed until GitHub Actions finishes.
- Current scope remains background-removal reliability only. Next checks: run CI, then exercise quick brush drags, undo/redo, colored and shadowed paper, thin outlines, enclosed pale details, and EXIF-rotated photos on device. Do not begin independent body-part motion until background removal has passed practical quality checks.


## 2026-10-09 follow-up: preserve source alpha

- Found and fixed a cutout correctness issue: both automatic paper removal and sampled-color removal previously initialized the output alpha mask as fully opaque. If an imported PNG already contained transparent pixels inside the drawing, cleanup could unintentionally make those pixels opaque. The alpha mask now starts from each source pixel's existing alpha, and removal only reduces it.
- Added a regression test in `test/background_removal_test.dart` covering already-transparent pixels enclosed within a drawing for both cleanup modes.
- Commits: brush interpolation `bbbff925ca0b5cd9b89a75c80d3db39dcbe3ca73`; preserve source alpha `296147ec7681b12cc6f9e1eab59a73b69b7aa50c`; transparency regression test `05d4969b1868c943a569413c90ce7dedd8eac54a`.
- CI status at the time of this note: the previous background-removal baseline run #50 passed; the new brush, alpha-preservation, and regression-test commits have runs #51–#54 queued/in progress and are not yet verified. Track the latest run here: [run #54](https://github.com/bdssmdkacem-dot/Rasmati/actions/runs/37926148985).
- Next: wait for analysis, tests, and APK build; address any failures. Then validate with real photos on the phone. No independent body-part motion work until background-removal QA is satisfactory.

- Additional brush geometry correction: `lib/background_editor.dart` now measures the correction-brush radius in pixels using the shorter image side. This aligns the generated mask with the circular brush shown on screen, instead of making the applied brush elliptical on non-square drawings. Commit: `31ef8b966b11629d82b74a4fbb8976c1a91149e6` — Match brush mask to circular on-screen size. Its CI run #56 is queued: [run #56](https://github.com/bdssmdkacem-dot/Rasmati/actions/runs/37926203587).


## 2026-10-09 verified follow-up and next QA step

- User confirmed the build succeeded. Independently verified GitHub Actions run #57 completed successfully for commit `35bc9676b1400095ff8a8061a4e49badf7dddf87`: [run #57](https://github.com/bdssmdkacem-dot/Rasmati/actions/runs/37926219568). Runs #51–#56 also completed successfully, including analysis, tests, and APK build across the latest implementation commits.
- Added one more regression test in `test/background_removal_test.dart` to ensure cleanup never increases partially transparent source pixels' alpha. Commit: `6cbabcd13ed34607b39621fe90dd54802127ae69` — Test partial transparency preservation.
- CI for this newest test commit is pending; verify its workflow before calling it green: [run #58](https://github.com/bdssmdkacem-dot/Rasmati/actions).
- Next acceptance pass is still background removal only: validate flat and shadowed white/cream paper, colored paper with tolerance changes, thin outlines, enclosed light details, already-transparent/partially transparent pixels, quick manual brush drags, undo/redo, and rotated photos. CI is necessary but not sufficient; do not claim real-world reliability until device/photo testing has been performed.


## 2026-10-09 milestone: guided character-part preparation (phase 1)

- The user has tried the app and approved moving from background cleanup to full-character motion, built step by step. Keep the original drawing and its colors/linework; do not present whole-image transforms as independent limb animation.
- Added `lib/character_part_editor.dart`: an Arabic/RTL guided part-marking screen for head, torso, left/right arms, and left/right legs. It supports per-part colored brush strokes, brush-size control, undo/redo, toggling the source-image preview, and local saving.
- Saving generates full-canvas-aligned transparent PNG layers for marked parts, a `base.png` with selected pixels removed to avoid drawing ghosts, and a local `manifest.json`. Ownership is deterministic: the first part in the fixed manifest order owns overlapping pixels. Original source file is not modified.
- Added a button in `lib/main.dart` to open this preparation screen from Animation Studio. Existing whole-image presets remain available as a fallback.
- Commits: editor `b49cf2af896d49e18fbdee348eeeccabc36fdfb0`; safe source-preview rendering `238f28b95ce31ebe6e5a6194df8ca506f3b3b009`; painter cleanup `721b333a3d24d713072b75b66dbafecbe55bf6f3`; Animation Studio entry point `a2143bea908b98fa91c46205ca7326178cd9bfb7`.
- CI status at this checkpoint: workflow runs #60–#63 are queued/in progress; no passing result is claimed for the new code yet. Latest run: [run #63](https://github.com/bdssmdkacem-dot/Rasmati/actions/runs/37940734008).
- Scope boundary: this is preparation/export of aligned part layers, not yet the jointed animation player. Next: wait for CI and fix any failures; add automated coverage for the rig-mask/layer extraction where practical; then load the saved layers into a rig preview with editable pivots, first proving arm/head rotation before adding walk cycles. Test thin strokes, overlaps, undo/redo, non-square images, and the source file's immutability. MP4 export remains separate.


- CI caught a compile-analysis error in the first editor commit: `Point<int>` was not qualified because `dart:math` is imported as `math`. Fixed it as `math.Point<int>` in commit `7fb3cf076bf1fcb01cf5fa410f606f8ba51442b2`. The initial run #60 failed at `flutter analyze`; the fix's own workflow is pending. Do not mark phase 1 green until a later run completes analysis, tests, and APK build.


- Follow-up interaction fix: made stroke point lists and rendered stroke lists immutable snapshots per rebuild so `CustomPainter.shouldRepaint` sees in-progress brush changes and undo/redo reliably. Commit: `987e0d7eb69b0f0a867aa341abe5fa8265d5ea69`. Its CI is pending.


- CI follow-up caught a second analyzer error: cleanup of the painter accidentally removed `CharacterPartEditor.imageFile`, still needed by the screen. Restored the widget field in commit `9141d43ede8e3bfb9b8f5e3aad55da3fd6cbee30`. Runs #61–#65 exposed the same or related analyzer issue before this correction; new CI is pending. Keep testing against the newest commit rather than treating an older run as verification.


- Removed unused brush-radius bookkeeping from the layer exporter in commit `a4dad95eb6e6b9f3427ab2f18cfa56b3c8c0d3c6` before final analyzer verification. CI for this cleanup is pending.


## 2026-10-09 phase 2: adjustable pivot preview

- User confirmed the latest build succeeded, so continued from the committed phase-1 part preparation.
- Added `lib/rig_joint_preview.dart`: a preview that composites the saved full-canvas base and transparent part layers, lets the user choose a part, drag its red pivot marker, adjust X/Y with sliders, test rotation, reset angle, and persist pivots to `joints.json`.
- Saving marked layers now opens the joint preview directly from `lib/character_part_editor.dart`.
- Commits: `73dd47c765ec4c103de9d676a46ac8805f30ca96` (pivot preview) and `a50400bc7aa16cf02aee99b034dd7b4fec20871e` (navigation).
- This is a first joint-placement/rotation prototype, not yet a full walk cycle. Layer masks are brush-selected, so good limb isolation and correctly placed pivots are necessary. Visual continuity at shoulders/hips and occlusion/overlap handling still need testing.
- Verify latest CI for phase 2 before declaring success; next improve pivot drag behavior and layer seam handling, then add a controlled first arm-wave motion.


## 2026-10-09 phase 3: independent limb-motion preview

- Verified GitHub Actions runs #73, #74, and #75 all completed successfully. These confirm the adjustable pivot screen, automatic navigation into it, and progress documentation build cleanly.
- Added `lib/character_motion_preview.dart`: local animation preview driven by the saved part PNG layers and normalized `joints.json` pivots. Includes looping wave, walk-cycle swing, and head-nod presets plus play/pause and reset.
- Connected the pivot screen to the new motion preview with an explicit “اختبار التلويح والمشي” action. Pivot values are saved before opening the preview, and the original drawing remains unchanged.
- Commits: motion preview `0b8b7a6d33e6e4cf8daf942647b0c912e5e76c5b`; pivot-screen integration `78810b656eccbf421cd2e6e3fd11d00ca48a4930`.
- Verification for these latest changes is pending; do not call phase 3 green until the newest GitHub Actions run completes analysis, tests, and APK build.
- Known quality limitation: this first motion player rotates the marked transparent layers around saved pivots. It cannot automatically reconstruct pixels hidden behind an arm or head, so poorly isolated masks may show seams/holes. Next fix any CI issues, then improve joint continuity/overlap and add targeted tests before expanding the walk cycle. Physical-device visual QA is still required.


- CI failure diagnosis for phase 3: runs #76–#78 stopped at `flutter analyze` because `_labels` was declared but never used in `lib/character_motion_preview.dart`. No tests or APK build ran in those workflows because the analyzer step failed first.
- Removed the unused field in commit `cbde90e2a0d4ebe4c424f5b4a03e228c1ec917e7` — “Fix analyzer failure in motion preview”. Verification for this fix is pending; wait for the new workflow to complete analysis, tests, and APK build before claiming success.


- Follow-up verification: CI runs #79 and #80 also failed at `flutter analyze`; after removing `_labels`, the remaining issue was `use_build_context_synchronously` at `lib/rig_joint_preview.dart:120`. Captured the Navigator before awaiting `_save()` in commit `315556464ccb410d53c12d97d226c682e1315158` so no BuildContext is read after the async gap. A fresh CI run must confirm this correction; tests/APK were skipped in the failed runs.


## 2026-10-09 — Free local AI animation integration (verification pending)

- Selected the open-source Flutter Animated Drawings implementation rather than a paid hosted API: it uses an ONNX pose model and skeletal animation locally on-device, so children's drawings are not uploaded to a third party.
- Pinned dependency commit: `f906a50f0fc2c227ff77ba1550c711fa8e73431e` from `konyshevgmbh/animated_drawings_flutter`.
- Added a home-screen entry point that picks a drawing and opens the AI annotation/skeleton workflow.
- Added `tool/prepare_ai_assets.sh` to stage the dependency's model and motion configuration assets at the root paths expected by the upstream code, and added the same preparation step to CI.
- Added local build instructions to README.
- Important: the upstream screen is a separate annotation/animation flow and its interface may not yet match Rasmati's Arabic styling. This is a real model-backed integration attempt, not a claim that animation quality has passed. CI must confirm dependency resolution, analysis, tests, and APK build; then a physical Android test must check model loading, segmentation, joints, and animation quality. No cloud API or paid service is configured.


## 2026-10-23 — articulated limb expansion; commercial acceptance remains open

- User explicitly rejected treating a small joint-overlap patch as a complete solution. The target is a comprehensive, commercial-quality character-motion system; do not advance to the next product phase until visual and device acceptance is met.
- Expanded the manual rig part palette so each arm can be marked as upper arm + forearm, and each leg as thigh + lower leg. This allows elbow and knee motion rather than rotating only a single rigid arm/leg. Updated part labels in the editor and pivot editor.
- Added default elbow/knee pivot locations in `lib/rig_geometry.dart`, lower-segment depth ordering, and coordinated forearm/lower-leg curves in `lib/motion_choreography.dart`. Added unit-test coverage for articulated part ordering, pivots, gait coupling, and finite motion curves.
- Updated README acceptance language to make clear that articulated segments are a testable intermediate architecture, not a claim of production quality. Remaining foundational work includes dependable segmentation, occlusion reconstruction for pixels hidden behind limbs, per-drawing hierarchical joints, visual regression on representative drawings, and Android-device verification.
- Commits on `fix/rig-preview-artifact-validation`: part split `695aac13158fb64db8cc8d68b427a62e904ab38d`; elbow/knee pivots `b4414989bd833c6a8d557aa15feb15b70b41360b`; articulated motion `428e61069fd5cae88a578ec9a4b57561fbeb675d`; pivot labels `ba000a3440d36e74d7bceb398b7126020cb84099`; choreography tests `95e2c8d0791d54fd315996cbe993fde383ecde60`; pivot tests `90d96bfbf8615cf642008ade24f11b04ba6bd50e`; forearm wave coordination `96cd962130408c42999e8474f620e7faf6a9dfdb`; README acceptance update `59224d8196d91f90c857ac0944d068360e990c4e`.
- CI verification for the newest code/doc commits is pending. Check the latest Actions run before reporting build status. Do not infer that APK build succeeded from analyzer/tests alone.
- Device and visual acceptance are not yet done: no representative drawing has been reviewed through the new upper/lower limb workflow, and no physical Android installation/test has been verified. Keep PR #1 in draft and do not merge to `main`.
- Next engineering step: run the latest CI and fix all failures; then implement a hierarchical rig model (shoulder→elbow→wrist and hip→knee→ankle) and reliable joint/occlusion handling rather than relying on approximate full-canvas pivots. Commercial acceptance requires checking original-art preservation and seam-free movement across multiple real drawings and device screenshots before moving to MP4/export phase.


- Follow-up implementation after the articulated-segment expansion: `lib/character_motion_preview.dart` and `lib/rig_joint_preview.dart` now apply a parent upper-arm/thigh transform to the matching forearm/lower-leg layer, so the child segment follows shoulder/hip rotation instead of rotating around a stationary image-space joint. Commits: `46a0013efd718fa36e45c703353efc42b2f91450` and `1ed2629404ea48a0453f9842a698082d6b3eb6f2`. This is a structural improvement, but it still needs CI and visual validation; it does not reconstruct hidden pixels or guarantee seamless joints.
- README follow-up commit: `8b6390e960ca46d7cd725d39c38a414b6c87315f`.


- Hierarchy follow-up: centralized the current parent graph in `RigGeometry.parentPart` and added tests for shoulder→forearm and hip→lower-leg links. The joint editor's segment labels now match the new part palette. Commits: `d107d79e127f01e55e9883ebc8036c23c46dd984`, `608b48e1b8d338ffb75b8a009119095bc4e9ff83`, `75473f53a06a9aadc96726be8dc2cbb83df03249`, `71832ae3573402d1594df7110263cc95982eefbc`, `06a0b043117c937236744bebfa25f4b5169cd753`.
- Latest CI for these changes is still pending; newest known run: [run #125](https://github.com/bdssmdkacem-dot/Rasmati/actions/runs/40002689892). The APK artifact is not yet verified for this code.
- Important remaining gap: this rig still depends on manual full-canvas masks and approximate pivots. Parent-child transforms are now represented for elbows/knees, but robust occlusion repair, adaptive pivot placement, and real-drawing visual/device acceptance remain release blockers.


## 2026-10-23 — acceptance contract locked; complete parent transform propagation

- Acceptance gate confirmed with the user: no more treating a local overlap patch or a green build as completion. Do not start the next product phase until the animation system passes visual and Android-device acceptance at a commercial-quality bar.
- Expanded the rig hierarchy from isolated elbow/knee parent pairs to a torso-rooted skeleton: torso → head, upper arms and thighs; upper arms → forearms; thighs → lower legs.
- Motion preview now applies each segment's own transform plus the ordered transforms of all ancestors. This means torso sway/bounce is inherited by head, shoulders, hips, elbows and knees. The joint editor's test preview uses the same ancestor graph so testing a torso/upper-arm/thigh rotation affects descendants consistently.
- Added unit tests for ancestor ordering and complete parent relationships in `test/rig_geometry_test.dart`.
- Commits: hierarchy `903257783d6b8ae40172b43fec1b69ba331615c1`; motion ancestor propagation `79f83f0ec96731dbc9b8a8e6c5eb54232a2c0c06`; joint-preview ancestor propagation `cc2265914b75a62e078a94dcfe5e7eb8522c4c0f`; hierarchy tests `d8e3dec1bca0704f3f163dfc1e473a560e48963f`.
- CI for this newest hierarchy code is pending. Earlier run #127 passed `flutter analyze` and `flutter test` and had started `flutter build apk --debug`, but that was for an earlier commit and does not prove the current code builds. Keep APK status unconfirmed until the latest run finishes and artifact upload is present.
- Known commercial blockers remain: current masks are brush-painted rather than robust semantic segmentation; shared joint pixels can create duplicate/ghost contours; hidden artwork behind a rotating part is not reconstructed; default pivots need per-character fitting; no representative drawing has passed a visual regression review; no physical Android install has been confirmed. These are explicit acceptance blockers, not optional polish.


## 2026-10-26 — CI verified; manual clone-repair added

- Verified run [#142](https://github.com/bdssmdkacem-dot/Rasmati/actions/runs/40379749960) on commit `53f9a3a753adf8d4b800b3ab079751c92b4d4304`: analyze, tests, debug APK build, and `rasmati-debug-apk` artifact upload all passed.
- Added manual clone-repair interaction to the part editor on the current branch: select a clean source point, then a target point under a region expected to be uncovered by motion. Repair copies pixels from the original artwork into the cut-out base, after rig-mask subtraction.
- Added a guard that refuses a source patch if more than 25% of its sampled circular area overlaps any moving-part mask, to reduce copying limb pixels into the background.
- README updated with the actual passing CI evidence and explicit limitations.
- **Important:** run #142 predates the clone-repair commits. CI for the latest head must pass separately. The repair workflow has not yet been visually inspected on real drawings; manual clone repair can leave seams and is not automatic hidden-anatomy reconstruction.
- **Still not verified:** wave/walk/nod on multiple actual drawings, APK installation and interaction on a physical Android phone, and source-art preservation under motion. Keep PR #1 open and do not merge to `main` until those gates have evidence.


## 2026-10-26 — Automatic local inpainting pass

- Added `lib/transparent_region_inpainting.dart`: fills only pixels explicitly marked as removed by rig masks, propagating neighboring visible colors inward; unrelated transparent canvas pixels remain untouched.
- Integrated inpainting into the saved base-layer pipeline before optional manual clone patches. The original source image remains unchanged.
- Added `test/transparent_region_inpainting_test.dart` for hole fill, untouched external transparency, source immutability, and mismatched mask size.
- Updated README to state the critical limitation: color propagation reduces cutout holes but cannot reconstruct actual hidden anatomy or complex original line art. It is not a semantic AI inpainting model.
- Latest CI at the time of this note is [run #147](https://github.com/bdssmdkacem-dot/Rasmati/actions/runs/40386422204). Flutter setup and SVG rendering started successfully; dependency resolution, analyze, tests, and APK build are still pending. No success claim for this new code yet.
- Visual wave/walk/nod review on multiple drawings and physical Android install remain outstanding. PR #1 remains unmerged.


## 2026-10-26 — Structure-aware exemplar inpainting

- Replaced the earlier local color propagation implementation with patch-based exemplar inpainting. The fill frontier prioritizes pixels near strong local gradients, compares candidate intact patches against the known neighborhood, then copies matched patch pixels into the cutout.
- Added an incremental frontier set to avoid rescanning every image pixel for each fill iteration.
- Added a regression test for continuing a one-pixel black line through a cutout, alongside tests for basic fill, untouched unrelated transparency, source immutability, and invalid mask dimensions.
- Updated README with the algorithm and explicit limitation: this is classical patch-based inpainting, not a learned semantic model; unique hidden anatomy and complex details cannot be guaranteed.
- Current CI for the most recent docs/test revision: [run #150](https://github.com/bdssmdkacem-dot/Rasmati/actions/runs/40386826159). It remains in progress; the new implementation is not yet verified by CI.
- **Still not verified:** actual wave/walk/nod visual regression on representative artwork and APK install/test on a physical Android device. Keep PR #1 open and unmerged.


## 2026-10-26 — Neural inpainting candidate evaluation

- Added [docs/inpainting-model-evaluation.md](docs/inpainting-model-evaluation.md) comparing the current patch fallback, LaMa/big-lama, Qualcomm LaMa-Dilated, and hosted APIs.
- Current decision: prototype a genuine learned model locally, with LaMa/big-lama as the first candidate to validate; Qualcomm's mobile LaMa-Dilated is a benchmark candidate only because its documented CelebAHQ domain may not suit children's drawings. No model has been integrated or approved yet.
- Privacy requirement documented: no drawing, crop, mask, embedding, or artwork-bearing telemetry may leave the device by default. Any future remote option requires separate explicit opt-in before upload. No hosted API is in the current plan.
- Proposed runtime must be pinned/checksum-verified, license-reviewed, run on-device, composite only inside the removed mask, and fall back to local exemplar repair on failure. A preview/undo is required before accepting generated pixels.
- Latest CI triggered for evaluation-doc commit: [run #159](https://github.com/bdssmdkacem-dot/Rasmati/actions/runs/40387083449), currently queued. No current-head analyze/test/APK pass is confirmed.
- PR #1 remains open and unmerged. Real-artwork visual regression and physical Android testing are still release gates.
