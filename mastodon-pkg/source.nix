# This file was generated by pkgs.mastodon.updateScript.
{ fetchgit, applyPatches }: let
  src = fetchgit {
    url = "https://github.com/glitch-soc/mastodon";
    rev = "660372d13069658f79da6fdf6b7f0e3e95dd7724";
    sha256 = "0gwgmgb74qfg8j3418bsn2zk5jxnc2pml6w7gjm796lykbxxjxmf";
  };
in applyPatches {
  inherit src;
  patches = [];
}
