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
        ];
      baseCiPackagesFor = pkgs: [
        pkgs.coreutils
        pkgs.deadnix
        pkgs.editorconfig-checker
        pkgs.git
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
