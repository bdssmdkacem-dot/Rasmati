#!/usr/bin/env bash
set -euo pipefail

# Stage assets from the exact dependency version resolved by pub. Do not guess
# the pub-cache checkout directory: its folder name is implementation-specific.
PACKAGE_ROOT="$(python3 - <<'PY'
import json
from pathlib import Path
from urllib.parse import unquote, urlparse

config_path = Path('.dart_tool/package_config.json').resolve()
if not config_path.is_file():
    raise SystemExit("Missing .dart_tool/package_config.json; run 'flutter pub get' first.")
config = json.loads(config_path.read_text(encoding='utf-8'))
package = next((p for p in config.get('packages', [])
                if p.get('name') == 'flutter_animated_drawings'), None)
if package is None:
    raise SystemExit("flutter_animated_drawings is not resolved in package_config.json.")
uri = package.get('rootUri', '')
parsed = urlparse(uri)
if parsed.scheme == 'file':
    root = Path(unquote(parsed.path))
elif not parsed.scheme:
    root = (config_path.parent / unquote(uri)).resolve()
else:
    raise SystemExit(f"Unsupported package root URI: {uri}")
if not root.is_dir():
    raise SystemExit(f"Resolved flutter_animated_drawings package directory is missing: {root}")
print(root)
PY
)"

SOURCE_ASSETS="$PACKAGE_ROOT/assets"
REQUIRED_FILES=(
  "$SOURCE_ASSETS/models/drawn_humanoid_pose.onnx"
  "$SOURCE_ASSETS/sample.png"
  "$SOURCE_ASSETS/bvh/cmu1"
  "$SOURCE_ASSETS/bvh/fair1"
  "$SOURCE_ASSETS/bvh/rokoko"
  "$SOURCE_ASSETS/config/motion"
  "$SOURCE_ASSETS/config/retarget"
)
for path in "${REQUIRED_FILES[@]}"; do
  if [[ ! -e "$path" ]]; then
    echo "Required AI asset is missing from resolved dependency: $path" >&2
    exit 1
  fi
done

mkdir -p assets/models assets/bvh/cmu1 assets/bvh/fair1 assets/bvh/rokoko \
  assets/config/motion assets/config/retarget
cp "$SOURCE_ASSETS/models/drawn_humanoid_pose.onnx" assets/models/drawn_humanoid_pose.onnx
cp "$SOURCE_ASSETS/sample.png" assets/sample.png
cp -R "$SOURCE_ASSETS/bvh/cmu1/." assets/bvh/cmu1/
cp -R "$SOURCE_ASSETS/bvh/fair1/." assets/bvh/fair1/
cp -R "$SOURCE_ASSETS/bvh/rokoko/." assets/bvh/rokoko/
cp -R "$SOURCE_ASSETS/config/motion/." assets/config/motion/
cp -R "$SOURCE_ASSETS/config/retarget/." assets/config/retarget/

test -s assets/models/drawn_humanoid_pose.onnx
test -s assets/config/motion/wave_hello.yaml
echo "Prepared local AI model and motion assets from resolved flutter_animated_drawings dependency."
