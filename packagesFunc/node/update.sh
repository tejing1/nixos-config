#! /usr/bin/env bash

node2nix() {
    nix run pkgs#nodePackages.node2nix -- "$@"
}

node2nix -i node-packages.json -c node-composition.nix -14
