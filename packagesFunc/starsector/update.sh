#! /usr/bin/env nix-shell
#! nix-shell -p bash coreutils curl jq nix jo
#! nix-shell -i bash

set -euo pipefail

# TODO: add hred dependency to nix-shell invocation instead, once it's in stable
if ! which hred &>/dev/null; then
    echo "error: hred not available in PATH" >&2
    exit 1
fi

cd "$(dirname "${BASH_SOURCE[0]}")"

version="$(curl -sSL https://fractalsoftworks.com/preorder | hred 'a[href*=starsector_linux] { @.href, ^button.linux_button}' -c | jq 'select(has(".scoped")) | .".href" | capture("^https://s3.amazonaws.com/fractalsoftworks/starsector/starsector_linux-(?<v>.+).zip$") | .v' -r)"

if [ -e pin.json ]; then
    if [ "$(jq '.version' -r <pin.json)" == "$version" ]; then
        echo "Nothing to do; already at version $version."
        exit 0
    else
        echo "Updating to version $version..."
    fi
else
    echo "No pinned version yet! Initializing with version $version..."
fi

url="https://s3.amazonaws.com/fractalsoftworks/starsector/starsector_linux-${version}.zip"
echo "Prefetching zip... (from $url)"
sha256="$(nix-prefetch-url --unpack "$url")"
hash="sha256-$(nix-hash --type sha256 --to-base16 "$sha256" | tr '[:lower:]' '[:upper:]' | basenc --base16 -d | base64)"

echo "Writing pin.json..."
jo -p version="$version" hash="$hash" > pin.json

echo "Success! Now on version $version"
