#!/usr/bin/env bash

set -euo pipefail

cd $(dirname $(realpath -eP $0))

nix-build --expr 'with import <nixpkgs-unstable> {}; callPackage ./update.nix {}'

./result/bin/update.sh --url https://github.com/glitch-soc/mastodon --ver v4.2.1-glitch --rev "660372d13069658f79da6fdf6b7f0e3e95dd7724"
