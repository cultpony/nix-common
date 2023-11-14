{
  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-23.05";
    nixpkgs-unstable.url = "github:nixos/nixpkgs/nixos-unstable";
    flake-utils.url = "github:numtide/flake-utils";
    agenix.url = "github:ryantm/agenix";
    agenix.inputs.nixpkgs.follows = "nixpkgs";
    cachix.url = "github:cachix/cachix/v1.5";
    zon2nix.url = "github:nix-community/zon2nix";
  };

  outputs = inputs@ { self, systems, nixpkgs, nixpkgs-unstable, flake-utils, ... }: flake-utils.lib.eachDefaultSystem
    (system: {
      devShells.default = (import nixpkgs rec {
        inherit system;
        config.allowUnfree = true;
      }).mkShell {
        buildInputs = with nixpkgs.legacyPackages.${system}; [
          inputs.agenix.packages.${system}.default
          inputs.cachix.packages.${system}.default
          inputs.zon2nix.packages.${system}.default
          nix-output-monitor
          zig
        ];
      };
      packages.mastodon = let pkgs = nixpkgs-unstable.legacyPackages.${system}; in with pkgs; (
        callPackage ./mastodon-pkg/default.nix { }
      );
      packages.monero-feather = let pkgs = nixpkgs.legacyPackages.${system}; in with pkgs; (
        callPackage ./monero-feather.nix { }
      );
      packages.hydrus = let pkgs = nixpkgs-unstable.legacyPackages.${system}; in with pkgs; (
        python3Packages.callPackage ./hydrus.nix {
          inherit miniupnpc swftools;
          inherit (qt6) wrapQtAppsHook qtbase qtcharts;
        }
      );
  
      checks.test-hydrus = self.packages.${system}.hydrus;
      checks.monero-feather = self.packages.${system}.monero-feather;
      checks.mastodon = self.packages.${system}.mastodon;
  }) //
  {
    lib = {
      cachix = import ./cachix.nix;
      cultpony_ssh_keys = import ./cultpony_ssh_keys.nix;
      common_setup = import ./common_setup.nix;
      gen_common = import ./gen_common.nix;
      no-rsa-ssh-hostkey = import ./no-rsa-ssh-hostkey.nix;
      pgbackrest = import ./pgbackrest.nix;
      restic_noprune = import ./restic_noprune.nix;
      rustic = import ./rustic.nix;
      mastodon = import ./mastodon.nix;
      mixins = {
        nginx = import ./nginx.nix;
        server-common = import ./server-common.nix;
        systemd-boot = import ./systemd-boot.nix;
        trusted-nix-caches = import ./trusted-nix-caches.nix;
      };
      desktop = {
        default = import ./default.nix;
      };
    };
  };
}
