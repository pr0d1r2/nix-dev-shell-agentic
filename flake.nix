{
  description = "Agentic Nix dev shell with CI/dev split";

  nixConfig = {
    extra-substituters = [ "https://pr0d1r2.cachix.org" ];
    extra-trusted-public-keys = [ "pr0d1r2.cachix.org-1:NfWjbhgAj41byXhCKiaE+av3Vnphm1fTezHXEGsiQIM=" ];
  };

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-25.11";
    nix-cavemem = {
      url = "github:pr0d1r2/nix-cavemem";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    nix-cavekit = {
      url = "github:pr0d1r2/nix-cavekit";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    rtk-src = {
      url = "github:rtk-ai/rtk/v0.38.0";
      flake = false;
    };
    nix-lefthook-git-conflict-markers-src = {
      url = "github:pr0d1r2/nix-lefthook-git-conflict-markers";
      flake = false;
    };
    nix-lefthook-git-no-local-paths-src = {
      url = "github:pr0d1r2/nix-lefthook-git-no-local-paths";
      flake = false;
    };
    nix-lefthook-markdownlint-src = {
      url = "github:pr0d1r2/nix-lefthook-markdownlint";
      flake = false;
    };
    nix-lefthook-missing-final-newline-src = {
      url = "github:pr0d1r2/nix-lefthook-missing-final-newline";
      flake = false;
    };
    nix-lefthook-nix-no-embedded-shell-src = {
      url = "github:pr0d1r2/nix-lefthook-nix-no-embedded-shell";
      flake = false;
    };
    nix-lefthook-statix-src = {
      url = "github:pr0d1r2/nix-lefthook-statix";
      flake = false;
    };
    nix-lefthook-trailing-whitespace-src = {
      url = "github:pr0d1r2/nix-lefthook-trailing-whitespace";
      flake = false;
    };
    nix-lefthook-deadnix-src = {
      url = "github:pr0d1r2/nix-lefthook-deadnix";
      flake = false;
    };
    nix-lefthook-editorconfig-checker-src = {
      url = "github:pr0d1r2/nix-lefthook-editorconfig-checker";
      flake = false;
    };
    nix-lefthook-nixfmt-src = {
      url = "github:pr0d1r2/nix-lefthook-nixfmt";
      flake = false;
    };
    nix-lefthook-shellcheck-src = {
      url = "github:pr0d1r2/nix-lefthook-shellcheck";
      flake = false;
    };
    nix-lefthook-shfmt-src = {
      url = "github:pr0d1r2/nix-lefthook-shfmt";
      flake = false;
    };
    nix-lefthook-typos-src = {
      url = "github:pr0d1r2/nix-lefthook-typos";
      flake = false;
    };
    nix-lefthook-yamllint-src = {
      url = "github:pr0d1r2/nix-lefthook-yamllint";
      flake = false;
    };
    nix-lefthook-ascii-only-src = {
      url = "github:pr0d1r2/nix-lefthook-ascii-only";
      flake = false;
    };
    nix-lefthook-file-size-check-src = {
      url = "github:pr0d1r2/nix-lefthook-file-size-check";
      flake = false;
    };
    nix-lefthook-gitleaks-src = {
      url = "github:pr0d1r2/nix-lefthook-gitleaks";
      flake = false;
    };
    nix-lefthook-unicode-lint-src = {
      url = "github:pr0d1r2/nix-lefthook-unicode-lint";
      flake = false;
    };
    nix-lefthook-execute-permissions-src = {
      url = "github:pr0d1r2/nix-lefthook-execute-permissions";
      flake = false;
    };
    nix-lefthook-tdd-order-bats-src = {
      url = "github:pr0d1r2/nix-lefthook-tdd-order-bats";
      flake = false;
    };
  };

  outputs =
    {
      nixpkgs,
      nix-cavemem,
      nix-cavekit,
      rtk-src,
      nix-lefthook-git-conflict-markers-src,
      nix-lefthook-git-no-local-paths-src,
      nix-lefthook-markdownlint-src,
      nix-lefthook-missing-final-newline-src,
      nix-lefthook-nix-no-embedded-shell-src,
      nix-lefthook-statix-src,
      nix-lefthook-trailing-whitespace-src,
      nix-lefthook-deadnix-src,
      nix-lefthook-editorconfig-checker-src,
      nix-lefthook-nixfmt-src,
      nix-lefthook-shellcheck-src,
      nix-lefthook-shfmt-src,
      nix-lefthook-typos-src,
      nix-lefthook-yamllint-src,
      nix-lefthook-ascii-only-src,
      nix-lefthook-file-size-check-src,
      nix-lefthook-gitleaks-src,
      nix-lefthook-unicode-lint-src,
      nix-lefthook-execute-permissions-src,
      nix-lefthook-tdd-order-bats-src,
      ...
    }:
    let
      supportedSystems = [
        "aarch64-darwin"
        "x86_64-darwin"
        "x86_64-linux"
        "aarch64-linux"
      ];
      forAllSystems =
        f: nixpkgs.lib.genAttrs supportedSystems (system: f nixpkgs.legacyPackages.${system});
      rtkFor =
        pkgs:
        import ./nix/rtk.nix {
          inherit pkgs;
          src = rtk-src;
        };
      lefthookPackagesFrom =
        inputs: system:
        nixpkgs.lib.mapAttrsToList (_: input: input.packages.${system}.default) (
          nixpkgs.lib.filterAttrs (
            name: input: nixpkgs.lib.hasPrefix "nix-lefthook-" name && input ? packages
          ) inputs
        );
      lefthookWrappersFor =
        pkgs:
        let
          wrap =
            name: src: extra:
            pkgs.writeShellApplication (
              {
                inherit name;
                text = builtins.readFile "${src}/${name}.sh";
              }
              // extra
            );
        in
        [
          (wrap "lefthook-git-conflict-markers" nix-lefthook-git-conflict-markers-src {
            runtimeInputs = [ pkgs.gnugrep ];
          })
          (wrap "lefthook-git-no-local-paths" nix-lefthook-git-no-local-paths-src {
            runtimeInputs = [ pkgs.gnugrep ];
          })
          (wrap "lefthook-markdownlint" nix-lefthook-markdownlint-src {
            runtimeInputs = [ pkgs.markdownlint-cli ];
          })
          (wrap "lefthook-missing-final-newline" nix-lefthook-missing-final-newline-src { })
          (pkgs.writeShellApplication {
            name = "lefthook-nix-no-embedded-shell";
            text = ''
              SCANNER="${nix-lefthook-nix-no-embedded-shell-src}/scan-nix-no-embedded-shell.sh"
            ''
            + builtins.readFile "${nix-lefthook-nix-no-embedded-shell-src}/lefthook-nix-no-embedded-shell.sh";
          })
          (wrap "lefthook-statix" nix-lefthook-statix-src {
            runtimeInputs = [ pkgs.statix ];
          })
          (wrap "lefthook-trailing-whitespace" nix-lefthook-trailing-whitespace-src {
            runtimeInputs = [ pkgs.gnugrep ];
          })
          (wrap "lefthook-deadnix" nix-lefthook-deadnix-src {
            runtimeInputs = [ pkgs.deadnix ];
          })
          (wrap "lefthook-editorconfig-checker" nix-lefthook-editorconfig-checker-src {
            runtimeInputs = [ pkgs.editorconfig-checker ];
          })
          (wrap "lefthook-nixfmt" nix-lefthook-nixfmt-src {
            runtimeInputs = [ pkgs.nixfmt ];
          })
          (wrap "lefthook-shellcheck" nix-lefthook-shellcheck-src {
            runtimeInputs = [ pkgs.shellcheck ];
          })
          (wrap "lefthook-shfmt" nix-lefthook-shfmt-src {
            runtimeInputs = [ pkgs.shfmt ];
          })
          (wrap "lefthook-typos" nix-lefthook-typos-src {
            runtimeInputs = [ pkgs.typos ];
          })
          (wrap "lefthook-yamllint" nix-lefthook-yamllint-src {
            runtimeInputs = [ pkgs.yamllint ];
          })
          (wrap "lefthook-ascii-only" nix-lefthook-ascii-only-src {
            runtimeInputs = [ pkgs.gnugrep ];
          })
          (wrap "lefthook-file-size-check" nix-lefthook-file-size-check-src {
            runtimeInputs = [
              pkgs.gawk
              pkgs.gnugrep
              pkgs.coreutils
            ];
          })
          (wrap "lefthook-gitleaks" nix-lefthook-gitleaks-src {
            runtimeInputs = [
              pkgs.gitleaks
              pkgs.coreutils
            ];
          })
          (wrap "lefthook-unicode-lint" nix-lefthook-unicode-lint-src {
            runtimeInputs = [
              pkgs.gnugrep
              pkgs.libiconv
              pkgs.python3
              pkgs.perl
            ];
          })
          (wrap "lefthook-execute-permissions" nix-lefthook-execute-permissions-src {
            runtimeInputs = [ pkgs.gnugrep ];
          })
          (wrap "lefthook-tdd-order-bats" nix-lefthook-tdd-order-bats-src { })
        ];
      baseCiPackagesFor = pkgs: [
        pkgs.coreutils
        pkgs.deadnix
        pkgs.editorconfig-checker
        pkgs.git
        pkgs.gitleaks
        pkgs.lefthook
        pkgs.nix
        pkgs.nixfmt
        pkgs.parallel
        pkgs.shellcheck
        pkgs.shfmt
        pkgs.statix
        pkgs.typos
        pkgs.yamllint
      ];
      batsWithLibsFor =
        pkgs:
        pkgs.bats.withLibraries (p: [
          p.bats-support
          p.bats-assert
          p.bats-file
        ]);
    in
    {
      lib.mkShells =
        {
          pkgs,
          inputs,
          ciPackages ? [ ],
          shellHook ? "",
          extraDevPackages ? [ ],
        }:
        let
          inherit (pkgs.stdenv.hostPlatform) system;
          batsWithLibs = batsWithLibsFor pkgs;
          allCiPackages =
            (lefthookWrappersFor pkgs)
            ++ (lefthookPackagesFrom inputs system)
            ++ (baseCiPackagesFor pkgs)
            ++ [ batsWithLibs ]
            ++ ciPackages;
        in
        {
          ci = pkgs.mkShell {
            packages = allCiPackages;
            BATS_LIB_PATH = "${batsWithLibs}/share/bats";
          };
          default = pkgs.mkShell {
            packages =
              allCiPackages
              ++ [
                nix-cavemem.packages.${system}.default
                nix-cavekit.packages.${system}.default
                (rtkFor pkgs)
                pkgs.gh
                pkgs.nodejs
              ]
              ++ extraDevPackages;
            shellHook = ''
              export NIX_CONFIG="experimental-features = nix-command flakes"
              [ -f .git/hooks/pre-commit ] || lefthook install
            ''
            + shellHook;
          };
          inherit batsWithLibs;
        };

      packages = forAllSystems (pkgs: {
        rtk = rtkFor pkgs;
      });

      templates.default = {
        path = ./template;
        description = "Nix project with agentic dev shell, CI split, lefthook, and vulnix scan";
      };

      devShells = forAllSystems (pkgs: {
        ci = pkgs.mkShell {
          packages = (baseCiPackagesFor pkgs) ++ (lefthookWrappersFor pkgs);
        };
        default = pkgs.mkShell {
          packages =
            (baseCiPackagesFor pkgs)
            ++ (lefthookWrappersFor pkgs)
            ++ [
              nix-cavemem.packages.${pkgs.stdenv.hostPlatform.system}.default
              nix-cavekit.packages.${pkgs.stdenv.hostPlatform.system}.default
              (rtkFor pkgs)
              pkgs.gh
              pkgs.markdownlint-cli
              pkgs.nodejs
            ];
          shellHook = ''
            export NIX_CONFIG="experimental-features = nix-command flakes"
            [ -f .git/hooks/pre-commit ] || lefthook install
          '';
        };
      });
    };
}
