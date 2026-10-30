#!/usr/bin/env bash
# Puts the crisis classifier into the app bundle's resources (not in git: ~250 MB):
#   Companion/Resources/CrisisClassifier.mlpackage   (Xcode compiles it to CrisisClassifier.mlmodelc)
#   Companion/Resources/CrisisModel/                 (tokenizer.json, tokenizer_config.json, crisis_config.json)
# Copies from ../crisis_layer/coreml when that exists, otherwise downloads from the private Hugging Face repo
# pranaybeela/crisis-classifier (needs `hf auth login`). The chat model (LFM3) is downloaded by the app itself.
set -euo pipefail
cd "$(dirname "$0")/.."
RES=Companion/Resources
mkdir -p "$RES/CrisisModel"
SRC=../crisis_layer/coreml
if [ ! -d "$SRC/CrisisClassifier.mlpackage" ]; then
  SRC=$(mktemp -d)
  hf download pranaybeela/crisis-classifier --include "coreml/*" "pytorch/tokenizer_config.json" --local-dir "$SRC"
  cp "$SRC/pytorch/tokenizer_config.json" "$SRC/coreml/"
  SRC="$SRC/coreml"
fi
rm -rf "$RES/CrisisClassifier.mlpackage"
cp -R "$SRC/CrisisClassifier.mlpackage" "$RES/"
cp "$SRC/tokenizer.json" "$SRC/tokenizer_config.json" "$SRC/crisis_config.json" "$RES/CrisisModel/"
echo "crisis classifier ready in $RES"
