#!/usr/bin/env bash
set -euo pipefail

# Explicit opt-in only: this downloads a ~208 MB third-party model artifact.
# Do not run in CI or include the model in the APK until license review is accepted.
MODEL_DIR="assets/models"
MODEL_PATH="$MODEL_DIR/lama_fp32.onnx"
MODEL_URL="https://huggingface.co/Carve/LaMa-ONNX/resolve/a3ee2fca54baebec351b8fa7786154ffa7555aa6/lama_fp32.onnx"
EXPECTED_SHA256="1faef5301d78db7dda502fe59966957ec4b79dd64e16f03ed96913c7a4eb68d6"

mkdir -p "$MODEL_DIR"
if [[ -e "$MODEL_PATH" ]]; then
  echo "Refusing to overwrite existing model: $MODEL_PATH" >&2
  exit 2
fi

tmp="$(mktemp "$MODEL_DIR/lama_fp32.onnx.XXXXXX")"
trap 'rm -f "$tmp"' EXIT
curl --fail --location --retry 3 --output "$tmp" "$MODEL_URL"
actual="$(sha256sum "$tmp" | awk '{print $1}')"
if [[ "$actual" != "$EXPECTED_SHA256" ]]; then
  echo "SHA-256 mismatch. Expected $EXPECTED_SHA256, got $actual" >&2
  exit 3
fi
mv "$tmp" "$MODEL_PATH"
trap - EXIT
echo "Verified model saved to $MODEL_PATH"
echo "SHA-256: $actual"
echo "Review docs/inpainting-model-evaluation.md before bundling or redistribution."
