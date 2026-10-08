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
