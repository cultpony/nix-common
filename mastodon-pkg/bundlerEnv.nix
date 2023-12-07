{ bundlerEnv
, ruby
, self
, system
}:
let
  pname = "mastodon";
  version = self.packages.${system}.mastodonSrc.version;
in
bundlerEnv {
  name = "${pname}-gems-${version}";
  inherit ruby version;
  gemdir = self.packages.${system}.mastodonSrc;
  gemset = import self.packages.${system}.mastodonGemSet;
  # This fix (copied from https://github.com/NixOS/nixpkgs/pull/76765) replaces the gem
  # symlinks with directories, resolving this error when running rake:
  #   /nix/store/451rhxkggw53h7253izpbq55nrhs7iv0-mastodon-gems-3.0.1/lib/ruby/gems/2.6.0/gems/bundler-1.17.3/lib/bundler/settings.rb:6:in `<module:Bundler>': uninitialized constant Bundler::Settings (NameError)
  postBuild = ''
    for gem in "$out"/lib/ruby/gems/*/gems/*; do
      cp -a "$gem/" "$gem.new"
      rm "$gem"
      # needed on macOS, otherwise the mv yields permission denied
      chmod +w "$gem.new"
      mv "$gem.new" "$gem"
    done
  '';
}
