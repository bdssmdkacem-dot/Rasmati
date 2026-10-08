# Development Progress — Rasmati

Last updated: 2026-10-08

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

- Commit: e6d72196902399a0c4a87bb2b5db1fc5948a96ff
- Message: Fix const lint after applying Rasmati logo
- [Commit link](https://github.com/bdssmdkacem-dot/Rasmati/commit/e6d72196902399a0c4a87bb2b5db1fc5948a96ff)

## Verification status

- Latest CI run: [Flutter CI run #7](https://github.com/bdssmdkacem-dot/Rasmati/actions/runs/37852006596)
- Baseline commit `6cbc700b400283c401ce9c4b141131a3754a35b4` passed `flutter pub get`, `flutter analyze`, `flutter test`, `flutter build apk --debug`, and artifact upload in [CI run #7](https://github.com/bdssmdkacem-dot/Rasmati/actions/runs/37852006596).
- Background-editor changes are **not yet fully verified**. The prior run passed analysis and tests but the APK build had not completed at the last check; see [CI run #9](https://github.com/bdssmdkacem-dot/Rasmati/actions/runs/37853132665).
- Branding/launcher-icon generation is **pending CI verification**. A first branding run found two const-lint infos in the home header; these were fixed in commit `e6d72196902399a0c4a87bb2b5db1fc5948a96ff`. Check the latest run before declaring the APK build clean.

## Known limitations / not implemented yet

- Motion presets animate the whole image; limbs/body parts are not independently rigged.
- Background removal and manual edge correction are implemented in code, but require CI completion and real-image/device QA before being considered production-ready.
- The new SVG brand sources are committed. Android launcher PNGs/resources are generated during CI, so check the latest workflow and APK artifact before claiming the launcher icon is verified in a build.
- MP4/video export is not implemented; the current UI marks export as not yet available.
- No commercial release readiness or device QA has been established yet.

## Next steps (in order)

1. Verify the latest branding/launcher-icon CI run, then verify the background-editor build and tests; fix any failure before marking either complete.
2. Validate background removal on sample drawings with dark lines, pale colors, white interior details, and non-white paper; tune flood-fill behavior and brush size if needed.
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
