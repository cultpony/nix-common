{
  self,
  system,
  yarn-berry,
  cacert,
  stdenvNoCC,
  hash ? "",
}: let
  src = self.packages.${system}.mastodonSrc;
in /*fetchYarnDeps {
  yarnLock = "${src}/yarn.lock";
  hash = "sha256-c7hbwSr4zi3tG69haX8zahTa/szCM2w/JGTxpA/H1v0=";
}*/

stdenvNoCC.mkDerivation {
  name = "yarn-deps";
  nativeBuildInputs = [ yarn-berry cacert ];
  dontInstall = true;
  inherit src;
  NODE_EXTRA_CA_CERTS = "${cacert}/etc/ssl/certs/ca-bundle.crt";
  buildPhase = ''
    mkdir -p $out

    export HOME=$(mktemp -d)
    echo $HOME

    export YARN_ENABLE_TELEMETRY=0
    export YARN_COMPRESSION_LEVEL=0

    cache="$(yarn config get cacheFolder)"
    yarn install --immutable --mode skip-build

    cp -r $cache/* $out/
  '';

  outputHashAlgo = "sha256";
  outputHash = hash;
  outputHashMode = "recursive";
}