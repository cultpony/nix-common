{
  callPackage,
  fetchYarnDeps,
}: let
  src = callPackage ./source.nix { };
in fetchYarnDeps {
  yarnLock = "${src}/yarn.lock";
  hash = "sha256-P7KswzsCusyiS4MxUFnC1HYMTQ6fLpIwd97AglCukIk=";
}
