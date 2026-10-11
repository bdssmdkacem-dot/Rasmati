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

The repository contains the Flutter app scaffold, Arabic-first home screen, a paper-background removal workflow, a manually painted part-layer prototype with pivot editing, and an entry point to an on-device AI animation engine. These are implementation milestones, not proof of production quality.

The simple preview in the general animation studio still applies transforms to the whole image. The manual rig prototype is also limited: painted strokes are used as part masks, so it can leave gaps, cut off hands/head edges, and produce visible seams when parts rotate. Neither limitation should be disguised by extra decorative effects.

## Motion redesign — acceptance criteria

Treat animation quality as a core engineering milestone. Do not mark this complete based only on a successful build.

1. **Character segmentation:** detect head, torso, upper/lower arms and legs (or equivalent articulated parts) from the drawing; provide correction tools for incorrect detections.
2. **Preserve the artwork:** retain original pixel colors and linework. Keep the source image immutable and work on derived layers.
3. **Joint continuity:** create overlap/underlay or joint-aware reconstruction so rotations do not expose transparent wedges, white cut lines, or missing hands/head. Pivot adjustment alone is not a fix for incomplete masks.
4. **Coordinated motion:** implement motion profiles for wave, walk, and nod with joint limits, eased timing, body balance, and coordinated limb motion. Avoid applying a single global rotation as a substitute for articulation.
5. **Fallback and correction:** when AI segmentation confidence is poor, let the user correct masks and joints; do not silently produce a broken animation.
6. **Visual regression:** add deterministic tests for layer alignment, source-image immutability, valid masks/manifests, pivot bounds, and missing/empty parts. Keep representative before/after samples for visual review.
7. **Device acceptance:** build and install the APK, then inspect real drawings on an Android phone, including thin lines, pale colors, overlapping limbs, and non-human drawings. Record failures and fix them before release.
8. **Export:** implement MP4 rendering with correct frame timing, dimensions, and audio policy; test that exported videos open and play before advertising export as available.

## Next development order

1. Inspect and test the current AI annotation flow and the saved-layer pipeline.
2. Replace stroke-only part masks with proper segmentation masks plus joint-aware overlap/reconstruction.
3. Connect corrected masks and pivots to the coordinated motion engine.
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
