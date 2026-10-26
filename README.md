# Rasmati — رسوماتي

Rasmati is an Android-first Flutter app that turns children's paper drawings into playful animations while preserving the original artwork.

## Product goals
- Capture a drawing with the camera or import it from the gallery.
- Preserve the untouched source image and create a separate transparent working copy.
- Let families correct background removal manually.
- Animate a character through independent body parts while preserving the child's lines, colors, and proportions.
- Export a reliable MP4 only after rendering and playback have been tested.
- Keep children's images on-device by default; any cloud processing must be optional and parent-approved.

## Current implementation status

The repository contains the Flutter app scaffold, Arabic-first home screen, paper-background removal, a manually painted articulated-part prototype with pivot editing, and an entry point to an on-device AI animation engine. These are implementation milestones, not proof of production quality. The manual rig now distinguishes upper arms from forearms and thighs from lower legs, with a torso-rooted parent graph so body motion propagates through head, shoulders, elbows, hips and knees. This is an engineering milestone, not evidence that joints are visually seamless.

The simple preview in the general animation studio still applies transforms to the whole image. The manual rig remains a prototype, not a commercial-quality rig: painted strokes are still the source of masks, default pivots are approximate, and the pipeline does not reconstruct pixels hidden behind moving parts. It can still leave gaps, cut off hands/head edges, or show seams. Adding lower-arm/lower-leg segments expands articulation but does not, by itself, solve segmentation, occlusion reconstruction, joint continuity, or visual quality.

## Motion redesign — acceptance criteria

Treat animation quality as a core engineering milestone. Do not mark this complete based only on a successful build.

1. **Character segmentation:** detect head, torso, upper/lower arms and legs (plus hands/feet where visible), or equivalent articulated parts, from the drawing; provide correction tools for incorrect detections. The current brush-marking flow is a correction/prototype path, not automatic segmentation.
2. **Preserve the artwork:** retain original pixel colors and linework. Keep the source image immutable and work on derived layers.
3. **Joint continuity:** create overlap/underlay or joint-aware reconstruction so rotations do not expose transparent wedges, white cut lines, or missing hands/head. Pivot adjustment alone is not a fix for incomplete masks.
4. **Coordinated motion:** implement motion profiles for wave, walk, and nod with joint limits, eased timing, body balance, and coordinated limb motion. Avoid applying a single global rotation as a substitute for articulation.
5. **Fallback and correction:** when AI segmentation confidence is poor, let the user correct masks and joints; do not silently produce a broken animation.
6. **Visual regression:** add deterministic tests for layer alignment, source-image immutability, valid masks/manifests, pivot bounds, and missing/empty parts. Keep representative before/after samples for visual review.
7. **Device acceptance:** build and install the APK, then inspect real drawings on an Android phone, including thin lines, pale colors, overlapping limbs, and non-human drawings. Record failures and fix them before release.
8. **Export:** implement MP4 rendering with correct frame timing, dimensions, and audio policy; test that exported videos open and play before advertising export as available.

## Rig-mask validation and manual repair — 2026-10-26

- Added filled polygon masks alongside the correction brush in `lib/character_part_editor.dart`.
- Added `RigMaskValidation` and unit tests for empty masks, fewer than two usable parts, unknown IDs, negative counts, and valid masks. The editor blocks empty/too-small masks before subtracting source pixels.
- Added a **manual clone-repair mode** for exposed areas: tap a clean source point, then tap the target where a limb will move away. The editor copies a circular patch from the original image into the base after the rig layers are removed. It rejects source patches where more than 25% of sampled pixels overlap moving-part masks to reduce limb-ghost contamination.
- Repair is intentionally manual and local. It does **not** infer hidden anatomy or reconstruct complex linework automatically; repeated textures, patch edges, and background gradients still require visual inspection.
- CI passed for commit `53f9a3a753adf8d4b800b3ab079751c92b4d4304`: `flutter analyze`, `flutter test`, `flutter build apk --debug`, and APK artifact upload all succeeded. The subsequent manual-repair commits need their own CI result before being accepted.
- APK artifact: [rasmati-debug-apk from successful run](https://github.com/bdssmdkacem-dot/Rasmati/actions/runs/40379749960).
- **Still blocked:** no visual regression review on multiple real drawings and no physical Android installation/test has been recorded. Do not merge this branch or claim commercial animation quality from CI alone.

## Next development order

1. Inspect and test the current AI annotation flow and the saved-layer pipeline.
2. Replace stroke-only part masks with reliable segmentation masks plus joint-aware overlap and occlusion reconstruction; keep the current articulated segments as a test harness, not the final quality bar.
3. The initial torso-rooted parent graph and ancestor-transform propagation are implemented. Still required: explicit wrist/ankle endpoints, per-drawing pivot fitting, hierarchy interaction tests on actual artwork, and validation that the rendering transform order does not clip or duplicate pixels.
4. Add regression tests and run `flutter analyze`, `flutter test`, and `flutter build apk --debug`.
5. Verify the animation visually on an Android device before moving to MP4 export or claiming production readiness.

## Development

Install Flutter stable, then run:

```sh
flutter pub get
bash tool/prepare_ai_assets.sh
flutter analyze
flutter test
flutter build apk --debug
```

## On-device AI and licensing

Rasmati integrates the open-source `flutter_animated_drawings` package from
https://github.com/konyshevgmbh/animated_drawings_flutter, pinned to commit
`f906a50f0fc2c227ff77ba1550c711fa8e73431e`. The inference model runs locally on the device; drawings are not sent to a hosted AI API by this flow. The model and motion files are staged from the pinned dependency rather than duplicated in Git.

Review `THIRD_PARTY_NOTICES.md` and all model/motion-asset terms before redistributing a production release. The upstream code license does not automatically settle every model or asset licensing question.

## Privacy

Rasmati is designed for children. Do not upload drawings or collect personal information without a clear need, appropriate parental consent, and a privacy policy.
