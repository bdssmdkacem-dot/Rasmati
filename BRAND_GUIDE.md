# Rasmati Visual Identity

## Brand idea
**رسوماتي — كل رسمة لها حكاية**  
A child's original drawing becomes a little story in motion. The identity should feel creative, safe, warm, and polished—not like a generic AI tool.

## Core mark
- Primary artwork: `assets/branding/rasmati_icon.svg`
- Compact mark: `assets/branding/rasmati_mark.svg`
- Android adaptive foreground source: `assets/branding/rasmati_foreground.svg`
- Functional icon family: `assets/branding/rasmati_icons.svg`
- Flutter-native home mark: `RasmatiMark` in `lib/branding.dart`

The paper sheet represents the child's original work. Three colorful hand-drawn strokes signal creativity and motion; the yellow star is the moment the drawing comes alive. Keep this motif recognizable and do not replace it with stock mascots or generated character art.

## Color tokens
| Token | Hex | Usage |
|---|---|---|
| Rasmati Purple | `#7558E8` | Primary actions, logo field, focus |
| Deep Violet | `#4C35B8` | Depth and pressed states |
| Warm Paper | `#FFFBF4` | Main canvas and light surfaces |
| Ink | `#253047` | Main text |
| Coral | `#FF7B6B` | Warm accent and expressive details |
| Mint | `#36B8A5` | Positive / creative accent |
| Sun Yellow | `#FFC857` | Highlights and rewards |
| Muted | `#778095` | Secondary copy |

## UI rules
- Arabic-first and right-to-left; preserve readable Arabic labels.
- Use purple for the primary action, not for every element.
- Pair coral, mint, and yellow as accents; do not make every card multicolored.
- Prefer warm off-white backgrounds, dark ink text, rounded surfaces, consistent stroke weights, and generous spacing.
- Use one icon style: rounded geometry, clear silhouettes, minimal detail, and the same five brand colors.
- Keep icons legible at small sizes; avoid text inside icons and avoid thin hairlines.
- Preserve the child's actual drawing and its original colors in product previews.

## App icon
The Android launcher icon is generated from the SVG source during CI using `flutter_launcher_icons`. The adaptive foreground is rendered separately over the purple background. This keeps the source artwork editable and makes generated platform resources reproducible rather than hand-edited build output.

## Asset workflow
1. Edit the SVG source files in `assets/branding/`.
2. CI renders source SVGs to temporary PNGs.
3. `flutter_launcher_icons` creates Android launcher resources during the build.
4. Keep `lib/branding.dart` colors and `RasmatiMark` aligned with the SVG mark.
5. After any identity change, run `flutter analyze`, `flutter test`, and `flutter build apk --debug`.

## Current scope
This is the first unified identity pass: core icon, mark, color tokens, functional icon sheet, home-screen mark, and reproducible Android launcher-icon generation. It does not by itself establish store-readiness; release screenshots, device checks, accessibility contrast, and final Play Store artwork still require review.
