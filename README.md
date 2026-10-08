# Rasmati — رسوماتي

Rasmati is an Android-first Flutter app that turns children's paper drawings into playful animations while preserving the original artwork.

## Product goals
- Capture a drawing with the camera or import it from the gallery.
- Keep the original image unchanged and offer a transparent working copy.
- Let children choose simple motions manually.
- Build toward independent limb animation and MP4 export.
- Keep children's images on-device by default; any cloud processing must be optional and parent-approved.

## MVP status
The repository is being initialized with a Flutter application scaffold. The first milestone is camera/gallery import, an animation preview, and a polished Arabic-first interface. Automatic background removal, rigging, and reliable MP4 export are follow-up milestones and must not be represented as complete until implemented and tested.

## Development
Install Flutter stable, then run:

```sh
flutter pub get
flutter analyze
flutter test
flutter run
```

## Privacy
Rasmati is designed for children. Do not upload drawings or collect personal information without a clear need, appropriate parental consent, and a privacy policy.
