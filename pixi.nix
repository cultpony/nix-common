{ lib
, fetchFromGitHub
, stdenv
, zig
, callPackage
}:

stdenv.mkDerivation {
  nativeBuildInputs = [
    zig.hook
  ];
  pname = "pixi";
  version = "0.1.0";

  src = fetchFromGitHub {
    owner = "foxnne";
    repo = "pixi";
    rev = "fc3029d95334155b4d5697c319e2d7ecd71f46e0";
    hash = "sha256-+vbdv+Y/c45fa4C5/Nr6Xf/rwEl2pT08b8y4PypD/R4=";
  };
  
  postPatch = ''
    echo $ZIG_GLOBAL_CACHE_DIR/p
    ln -s ${callPackage ./pixi.deps.nix { }} $ZIG_GLOBAL_CACHE_DIR/p
  '';

  buildPhase = ''
    zig build -Dcpu=baseline -Doptimize=ReleaseSafe "--global-cache-dir=$ZIG_GLOBAL_CACHE_DIR"
  '';

  dontUseZigBuild = true;
  dontUseZigCheck = true;
}