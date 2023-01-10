#! /usr/bin/env bash

set -eu -o pipefail

cd "$(dirname "${BASH_SOURCE[0]}")"

system="$(nix eval --impure --expr 'builtins.currentSystem')"

node2nix="$(nix build --print-out-paths ../..#inputs.nixpkgs.legacyPackages."$system".nodePackages.node2nix)"

"$node2nix/bin/node2nix" -i node-packages.json -c node-composition.nix -14

rm ./result
