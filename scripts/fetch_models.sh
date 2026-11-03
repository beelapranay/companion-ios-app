#!/usr/bin/env bash
# Puts the crisis classifier into the app bundle's resources (not in git: ~250 MB):
#   Companion/Resources/CrisisClassifier.mlpackage   (Xcode compiles it to CrisisClassifier.mlmodelc)
#   Companion/Resources/CrisisModel/                 (tokenizer.json, tokenizer_config.json, crisis_config.json)
# Copies from ../crisis_layer/coreml when that exists, otherwise downloads from the private Hugging Face repo
# pranaybeela/crisis-classifier (needs `hf auth login`).
# Also copies the fine-tuned chat model (~945 MB) into Companion/Resources/FriendModel/ from
# ../models/LFM3-1.7B-friend-$FRIEND_VERSION-MLX-4bit (AppModel.useFineTuned). FRIEND_VERSION defaults to v3 (run
# r16-v3, epoch 2); `FRIEND_VERSION=v2 scripts/fetch_models.sh` restores the v2 backup. Both share one system
# prompt (SystemPrompt.finetuned). With useFineTuned off, the app downloads the base LFM3 itself instead.
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

FRIEND_VERSION=${FRIEND_VERSION:-v3}
FRIEND=../models/LFM3-1.7B-friend-$FRIEND_VERSION-MLX-4bit
if [ -d "$FRIEND" ]; then
  rm -rf "$RES/FriendModel"
  mkdir -p "$RES/FriendModel"
  # weights, config and tokenizer only; the Python files and README aren't needed on device
  cp "$FRIEND"/{config.json,generation_config.json,model.safetensors,model.safetensors.index.json} "$RES/FriendModel/"
  cp "$FRIEND"/{tokenizer.json,tokenizer_config.json,chat_template.jinja} "$RES/FriendModel/"
  echo "fine-tuned chat model ($FRIEND_VERSION) ready in $RES/FriendModel"
else
  echo "warning: $FRIEND not found; set AppModel.useFineTuned = false to use the base model from the Hub" >&2
fi
