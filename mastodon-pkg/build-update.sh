#!/usr/bin/env bash

set -euo pipefail

cd $(dirname $(realpath -eP $0))

nix-build --expr 'with import <nixpkgs-unstable> {}; callPackage ./update.nix {}'

./result/bin/update.sh --url https://github.com/glitch-soc/mastodon --ver v4.2.1-glitch --rev "18eacc7a07233f39170a914fcf1806f4e9c3485b"
