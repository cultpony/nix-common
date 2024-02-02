{
  self,
  system,
  callPackage,
  fetchYarnDeps,
}: let
  src = self.packages.${system}.mastodonSrc;
in fetchYarnDeps {
  yarnLock = "${src}/yarn.lock";
  hash = "sha256-c7hbwSr4zi3tG69haX8zahTa/szCM2w/JGTxpA/H1v0=";
}
