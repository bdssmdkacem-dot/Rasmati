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

## Latest commit

- Commit: 6cbc700b400283c401ce9c4b141131a3754a35b4
- Message: Fix flutter analyze unused constant
- [Commit link](https://github.com/bdssmdkacem-dot/Rasmati/commit/6cbc700b400283c401ce9c4b141131a3754a35b4)

## Verification status

- Latest CI run: [Flutter CI run #7](https://github.com/bdssmdkacem-dot/Rasmati/actions/runs/37852006596)
- At last check, the run was IN PROGRESS. Do not claim the fix/build is fully verified until analysis, tests, and APK build have completed successfully.
- APK artifact should be available from the Actions run page only if the workflow completes successfully.

## Known limitations / not implemented yet

- Motion presets animate the whole image; limbs/body parts are not independently rigged.
- Background removal and manual edge correction are not implemented yet.
- MP4/video export is not implemented; the current UI marks export as not yet available.
- No commercial release readiness or device QA has been established yet.

## Next steps (in order)

1. Check the latest GitHub Actions run and resolve any actual failing step before adding features.
2. Add a safe, usable background-removal workflow with manual correction while preserving the original drawing.
3. Introduce explicit editable regions / body-part segmentation and a user-controlled rigging workflow; avoid pretending automatic rigging is reliable before it is implemented and tested.
4. Implement video export (MP4) and verify on a real Android device.
5. Add regression tests for import, preview controls, editing, and export; verify privacy/storage behavior.
6. Only then assess release signing, app icon, permissions, performance, and Play Store readiness.

## Continuation rules

After each substantial change:
- Record what changed and why, including the original failure and fix.
- Record touched files and commit SHA.
- Record exact CI/test/build outcome and link; distinguish pending from passing.
- Update known limitations and the next concrete step.
- Never describe an unimplemented feature as working, and do not undo product decisions above without an explicit reason.
