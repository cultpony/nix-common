{ self
, lib
, stdenv
, nodejs-slim
, bundlerEnv
, nixosTests
, yarn
, callPackage
, imagemagick
, ffmpeg
, file
, ruby_3_2
, writeShellScript
, fetchYarnDeps
, fixup_yarn_lock
, brotli
, gcc-unwrapped
, glibc
, writeShellScriptBin
, yarn-berry
, system

  # Allow building a fork or custom version of Mastodon:
, pname ? "mastodon-pony-social"
, patches ? []
, version ? self.packages.${system}.mastodonSrc.version
, dependenciesDir ? ./.  # Should contain gemset.nix, yarn.nix and package.json.
, gemset ? ./. + "/gemset.nix"
, ruby ? ruby_3_2
}:

stdenv.mkDerivation rec {
  inherit pname version;

  # Using overrideAttrs on src does not build the gems and modules with the overridden src.
  # Putting the callPackage up in the arguments list also does not work.
  src = self.packages.${system}.mastodonSrc;

  mastodonGems = self.packages.${system}.mastodonGems;

  mastodonEmojiImporter = self.packages.${system}.mastodonEmojiImporter;

  mastodonModules = stdenv.mkDerivation {
    pname = "${pname}-modules";
    inherit src version;

    yarnOfflineCache = self.packages.${system}.mastodonYarnCache;

    nativeBuildInputs = [ yarn-berry nodejs-slim mastodonGems mastodonGems.wrappedRuby brotli ];

    RAILS_ENV = "production";
    NODE_ENV = "production";

    buildPhase = ''
      runHook preBuild
      
      export HOME=$PWD
      # This option is needed for openssl-3 compatibility
      # Otherwise we encounter this upstream issue: https://github.com/mastodon/mastodon/issues/17924
      export NODE_OPTIONS=--openssl-legacy-provider
      
      export YARN_ENABLE_TELEMETRY=0
      mkdir -p ~/.yarn/berry
      ln -sf $yarnOfflineCache ~/.yarn/berry/cache

      yarn install --immutable --immutable-cache

      patchShebangs ~/bin
      patchShebangs ~/node_modules

      # skip running yarn install
      rm -rf ~/bin/yarn

      OTP_SECRET=precompile_placeholder SECRET_KEY_BASE=precompile_placeholder \
        rails assets:precompile
      yarn cache clean
      rm -rf ~/node_modules/.cache

      # Create missing static gzip and brotli files
      gzip --best --keep ~/public/assets/500.html
      gzip --best --keep ~/public/packs/report.html
      find ~/public/assets -maxdepth 1 -type f -name '.*.json' \
        -exec gzip --best --keep --force {} ';'
      brotli --best --keep ~/public/packs/report.html
      find ~/public/assets -type f -regextype posix-extended -iregex '.*\.(css|js|json|html)' \
        -exec brotli --best --keep {} ';'

      runHook postBuild
    '';

    installPhase = ''
      runHook preInstall
      
      mkdir -p $out/public
      cp -r node_modules $out/node_modules
      cp -r public/assets $out/public
      cp -r public/packs $out/public

      runHook postInstall
    '';
  };

  propagatedBuildInputs = [ imagemagick ffmpeg file mastodonGems.wrappedRuby ];
  buildInputs = [ mastodonGems nodejs-slim ];

  buildPhase = ''
    runHook preBuild
    
    ln -s $mastodonModules/node_modules node_modules
    ln -s $mastodonModules/public/assets public/assets
    ln -s $mastodonModules/public/packs public/packs

    patchShebangs bin/
    for b in $(ls $mastodonGems/bin/)
    do
      if [ ! -f bin/$b ]; then
        ln -s $mastodonGems/bin/$b bin/$b
      fi
    done

    # Remove execute permissions
    chmod 0444 public/emoji/*.svg

    # Create missing static gzip and brotli files
    find public -maxdepth 1 -type f -regextype posix-extended -iregex '.*\.(css|js|svg|txt|xml)' \
      -exec gzip --best --keep --force {} ';' \
      -exec brotli --best --keep {} ';'
    find public/emoji -type f -name '.*.svg' \
      -exec gzip --best --keep --force {} ';' \
      -exec brotli --best --keep {} ';'
    ln -s assets/500.html.gz public/500.html.gz
    ln -s assets/500.html.br public/500.html.br
    ln -s packs/sw.js.gz public/sw.js.gz
    ln -s packs/sw.js.br public/sw.js.br
    ln -s packs/sw.js.map.gz public/sw.js.map.gz
    ln -s packs/sw.js.map.br public/sw.js.map.br

    rm -rf log
    ln -s /var/log/mastodon log
    ln -s /tmp tmp

    runHook postBuild
  '';

  importEmojiScript = writeShellScriptBin "import_emoji.sh" ''
    export PATH="${imagemagick}/bin:$PATH"

    exec ./bin/bundle exec rails runner import_emoji.rb $@
  '';

  installPhase =
    let
      run-streaming = writeShellScript "run-streaming.sh" ''
        # NixOS helper script to consistently use the same NodeJS version the package was built with.
        ${nodejs-slim}/bin/node ./streaming
      '';
    in
    ''
      runHook preInstall
      
      mkdir -p $out
      cp -r * $out/
      cp ${mastodonEmojiImporter}/import_emoji.rb $out/import_emoji.rb
      ln -s ${importEmojiScript}/bin/import_emoji.sh $out/bin/import_emoji.sh
      ln -s ${run-streaming} $out/run-streaming.sh

      runHook postInstall
    '';

  passthru = {
    tests.mastodon = nixosTests.mastodon;
    updateScript = callPackage ./update.nix { };
  };

  meta = with lib; {
    description = "Self-hosted, globally interconnected microblogging software based on ActivityPub";
    homepage = "https://joinmastodon.org";
    license = licenses.agpl3Plus;
    platforms = [ "x86_64-linux" "i686-linux" "aarch64-linux" "aarch64-apple-darwin" "aarch64-darwin" ];
    maintainers = with maintainers; [ happy-river erictapen izorkin ghuntley ];
  };
}
