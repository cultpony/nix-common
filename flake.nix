{
  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-24.05";
    nixpkgs-unstable.url = "github:nixos/nixpkgs/nixos-unstable";
    flake-utils.url = "github:numtide/flake-utils";
    agenix.url = "github:ryantm/agenix";
    agenix.inputs.nixpkgs.follows = "nixpkgs";
    cachix.url = "github:cachix/cachix/v1.5";
    zon2nix.url = "github:nix-community/zon2nix";
  };

  outputs =
    inputs@{ self, systems, nixpkgs, nixpkgs-unstable, flake-utils, ... }:
    flake-utils.lib.eachDefaultSystem ((system:
      let
        pkgs = import nixpkgs {
          inherit system;
        };
        pkgs-unstable = import nixpkgs-unstable {
          inherit system;
          overlays = [
            ];
        };
      in {
        devShells.default = (import nixpkgs {
          inherit system;
          config.allowUnfree = true;
        }).mkShell {
          buildInputs = with pkgs; [
            inputs.agenix.packages.${system}.default
            inputs.cachix.packages.${system}.default
            inputs.zon2nix.packages.${system}.default
            nix-output-monitor
            nix-update
            zig
            nix-tree
            nixpkgs-fmt
            nixfmt
            python310Packages.nix-prefetch-github
          ];
        };
        packages = {
          monero-feather = with pkgs;
            (qt6.callPackage ./monero-feather.nix { });

          hydrus = with import nixpkgs-unstable {
            inherit system;
            overlays =
              if system == "aarch64-darwin" || system == "x86_64-darwin" then
                [
                  (final: prev: rec {
                    python311 = prev.python311.override {
                      packageOverrides = python-final: python-prev: {
                        pyqt6 = python-prev.pyqt6.overrideAttrs (old: {
                          # fix build with qt 6.6
                          env.NIX_CFLAGS_COMPILE =
                            "-fpermissive -Wno-error=address-of-temporary ${old.env.NIX_CFLAGS_COMPILE}";
                        });
                        av = python-prev.av.overrideAttrs (old: {
                          doCheck = false;
                          disabledTestPaths = [
                            "tests/test_encode.py"
                            "tests/test_doctests.py"
                            "tests/test_timeout.py"
                          ];
                        });
                        imageio = python-prev.imageio.overrideAttrs (old: {
                          doCheck = false;
                          disabledTestPaths = [
                            "tests/test_pyav.py"
                            "tests/test_freeimage.py"
                            "tests/test_ffmpeg.py"
                            "tests/test_pillow.py"
                            "tests/test_spe.py"
                            "tests/test_swf.py"
                          ];
                        });
                      };
                    };

                    python311Packages = python311.pkgs;
                  })
                ]
              else
                [ ];
          };
            (python311Packages.callPackage ./hydrus.nix {
              pythonPackages = python311Packages;
              inherit miniupnpc swftools;
              inherit (qt6) wrapQtAppsHook qtbase qtcharts;
            });

          general-vscode = with import nixpkgs-unstable {
            inherit system;
            config.allowUnfree = true;
          };
            ((vscode-with-extensions.override {
              vscodeExtensions = with vscode-extensions; [
                arrterian.nix-env-selector
                bbenoist.nix
                brettm12345.nixfmt-vscode
                elixir-lsp.vscode-elixir-ls
                github.codespaces
                github.vscode-github-actions
                github.vscode-github-actions
                github.vscode-pull-request-github
                gruntfuggly.todo-tree
                jnoortheen.nix-ide
                rust-lang.rust-analyzer
                mkhl.direnv
                ms-azuretools.vscode-docker
                ms-dotnettools.csharp
                ms-kubernetes-tools.vscode-kubernetes-tools
                ms-vscode-remote.remote-containers
                ms-vscode-remote.remote-ssh
                ms-vscode-remote.remote-ssh
                ms-vscode.hexeditor
                serayuzgur.crates
                shd101wyy.markdown-preview-enhanced
                tamasfe.even-better-toml # bungcip.better-toml
              ];
            }).overrideAttrs (old: { pname = "vscode"; }));
        };

        checks.test-hydrus = self.packages.${system}.hydrus;
        checks.monero-feather = self.packages.${system}.monero-feather;
      })) // {
        lib = {
          cachix = import ./cachix.nix;
          cultpony_ssh_keys = import ./cultpony_ssh_keys.nix;
          common_setup = import ./common_setup.nix;
          gen_common = import ./gen_common.nix;
          no-rsa-ssh-hostkey = import ./no-rsa-ssh-hostkey.nix;
          pgbackrest = import ./pgbackrest.nix;
          restic_noprune = import ./restic_noprune.nix;
          rustic = import ./rustic.nix;
          mixins = {
            nginx = import ./nginx.nix;
            server-common = import ./server-common.nix;
            systemd-boot = import ./systemd-boot.nix;
            trusted-nix-caches = import ./trusted-nix-caches.nix;
          };
          desktop = { default = import ./default.nix; };
        };
      };
}
