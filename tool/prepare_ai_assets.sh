#!/usr/bin/env bash
set -euo pipefail

# Stage the model and motion configuration from the pinned open-source Flutter
# Animated Drawings package. The app runs inference locally; no drawing upload.
CACHE_ROOT="${PUB_CACHE:-$HOME/.pub-cache}/git/checkouts"
MODEL_PATH="$(find "$CACHE_ROOT" -path '*/assets/models/drawn_humanoid_pose.onnx' -print -quit 2>/dev/null || true)"
if [[ -z "$MODEL_PATH" ]]; then
  echo "AI model not found in pub cache. Run 'flutter pub get' first." >&2
  exit 1
fi
SOURCE_ASSETS="${MODEL_PATH%/models/drawn_humanoid_pose.onnx}"

mkdir -p assets/models assets/bvh/cmu1 assets/bvh/fair1 assets/bvh/rokoko \
  assets/config/motion assets/config/retarget
cp "$MODEL_PATH" assets/models/drawn_humanoid_pose.onnx
cp "$SOURCE_ASSETS/sample.png" assets/sample.png
cp -R "$SOURCE_ASSETS/bvh/cmu1/." assets/bvh/cmu1/
cp -R "$SOURCE_ASSETS/bvh/fair1/." assets/bvh/fair1/
cp -R "$SOURCE_ASSETS/bvh/rokoko/." assets/bvh/rokoko/
cp -R "$SOURCE_ASSETS/config/motion/." assets/config/motion/
cp -R "$SOURCE_ASSETS/config/retarget/." assets/config/retarget/

test -s assets/models/drawn_humanoid_pose.onnx
test -s assets/config/motion/wave_hello.yaml
echo "Prepared local AI model and motion assets from pinned flutter_animated_drawings dependency."
