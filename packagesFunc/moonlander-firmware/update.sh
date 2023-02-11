#! /usr/bin/env nix-shell
#! nix-shell -p bash coreutils curl unzip nvfetcher
#! nix-shell -i bash

layout_id="GLExg"

set -euo pipefail

cd "$(dirname "${BASH_SOURCE[0]}")"

cleanup() {
    [ -n "${f:-}" ] && [ -e "$f" ] && rm -f -- "$f"
}

trap cleanup EXIT
f="$(mktemp --tmpdir oryx-source-XXXXXXX.zip)"
echo Downloading latest source zip...
curl -L "https://oryx.zsa.io/$layout_id/${1:-latest}/source" >"$f"

echo
echo Testing zip integrity...
unzip -t "$f"

echo
echo Replacing keymap directory...
rm -rf keymap
unzip -j "$f" '*_source/*' -d keymap

echo
echo Updating qmk_firmware commit...
nvfetcher
