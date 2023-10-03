#! /usr/bin/env nix-shell
#! nix-shell -I nixpkgs=flake:github:nixos/nixpkgs/nixos-unstable
#! nix-shell -p bash coreutils curl jq nix jo hred
#! nix-shell -i bash

set -euo pipefail

cd "$(dirname "${BASH_SOURCE[0]}")"

url="$(curl -sSL https://fractalsoftworks.com/preorder | hred 'a[href*=starsector_linux] { @.href, ^button.linux_button}' -c | jq 'select(has(".scoped")) | .".href"' -r)"
version="${url##*/starsector_linux-}"
version="${version%.zip}"

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

echo "Prefetching zip... (from $url)"
sha256="$(nix-prefetch-url --unpack "$url")"
hash="sha256-$(nix-hash --type sha256 --to-base16 "$sha256" | tr '[:lower:]' '[:upper:]' | basenc --base16 -d | base64)"

echo "Writing pin.json..."
jo -p version="$version" url="$url" hash="$hash" > pin.json

echo "Success! Now on version $version"
