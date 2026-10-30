#!/usr/bin/env bash
# Downloads the bundled embedding model into assets/models/ (it is too
# large for GitHub, so it is not committed). Verifies size and SHA-256;
# skips the download when the file is already correct. Run once after
# cloning, before `flutter run` or `flutter build`.
set -euo pipefail
cd "$(dirname "$0")/.."
NAME=bge-base-en-v1.5-q8_0.gguf
URL="https://huggingface.co/CompendiumLabs/bge-base-en-v1.5-gguf/resolve/main/$NAME"
SHA=ad1afe72cd6654a558667a3db10878b049a75bfd72912e1dabb91310d671173c
SIZE=117974304
DEST=assets/models/$NAME
mkdir -p assets/models
if [ -f "$DEST" ] && [ "$(stat -f %z "$DEST" 2>/dev/null || stat -c %s "$DEST")" = "$SIZE" ] \
   && [ "$(shasum -a 256 "$DEST" | awk '{print $1}')" = "$SHA" ]; then
  echo "$DEST is present and verified"; exit 0
fi
echo "downloading $NAME ($((SIZE / 1048576)) MB)…"
curl -L --retry 3 -o "$DEST.part" "$URL"
have=$(shasum -a 256 "$DEST.part" | awk '{print $1}')
if [ "$have" != "$SHA" ]; then rm -f "$DEST.part"; echo "checksum mismatch: $have"; exit 1; fi
mv "$DEST.part" "$DEST"
echo "ok: $DEST"
