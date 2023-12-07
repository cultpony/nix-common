{
  self,
  system,
  callPackage,
  fetchYarnDeps,
}: let
  src = self.packages.${system}.mastodonSrc;
in fetchYarnDeps {
  yarnLock = "${src}/yarn.lock";
  hash = "sha256-P7KswzsCusyiS4MxUFnC1HYMTQ6fLpIwd97AglCukIk=";
}
