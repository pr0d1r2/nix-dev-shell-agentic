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
    nix-lefthook-git-conflict-markers = {
      url = "github:pr0d1r2/nix-lefthook-git-conflict-markers";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    nix-lefthook-git-no-local-paths = {
      url = "github:pr0d1r2/nix-lefthook-git-no-local-paths";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    nix-lefthook-missing-final-newline = {
      url = "github:pr0d1r2/nix-lefthook-missing-final-newline";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    nix-lefthook-nix-no-embedded-shell = {
      url = "github:pr0d1r2/nix-lefthook-nix-no-embedded-shell";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    nix-lefthook-trailing-whitespace = {
      url = "github:pr0d1r2/nix-lefthook-trailing-whitespace";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    nix-lefthook-markdownlint = {
      url = "github:pr0d1r2/nix-lefthook-markdownlint";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    nix-lefthook-statix = {
      url = "github:pr0d1r2/nix-lefthook-statix";
      inputs = {
        nixpkgs.follows = "nixpkgs";
        nix-lefthook-git-conflict-markers.follows = "nix-lefthook-git-conflict-markers";
        nix-lefthook-git-no-local-paths.follows = "nix-lefthook-git-no-local-paths";
        nix-lefthook-missing-final-newline.follows = "nix-lefthook-missing-final-newline";
        nix-lefthook-trailing-whitespace.follows = "nix-lefthook-trailing-whitespace";
      };
    };
    nix-lefthook-taplo = {
      url = "github:pr0d1r2/nix-lefthook-taplo";
      inputs = {
        nixpkgs.follows = "nixpkgs";
        nix-lefthook-git-conflict-markers.follows = "nix-lefthook-git-conflict-markers";
        nix-lefthook-git-no-local-paths.follows = "nix-lefthook-git-no-local-paths";
        nix-lefthook-missing-final-newline.follows = "nix-lefthook-missing-final-newline";
        nix-lefthook-nix-no-embedded-shell.follows = "nix-lefthook-nix-no-embedded-shell";
        nix-lefthook-trailing-whitespace.follows = "nix-lefthook-trailing-whitespace";
      };
    };
    nix-lefthook-unicode-lint = {
      url = "github:pr0d1r2/nix-lefthook-unicode-lint";
      inputs = {
        nixpkgs.follows = "nixpkgs";
        nix-lefthook-git-conflict-markers.follows = "nix-lefthook-git-conflict-markers";
        nix-lefthook-git-no-local-paths.follows = "nix-lefthook-git-no-local-paths";
        nix-lefthook-missing-final-newline.follows = "nix-lefthook-missing-final-newline";
        nix-lefthook-nix-no-embedded-shell.follows = "nix-lefthook-nix-no-embedded-shell";
        nix-lefthook-trailing-whitespace.follows = "nix-lefthook-trailing-whitespace";
      };
    };
  };

  outputs =
    {
      self,
      nixpkgs,
      nix-cavemem,
      nix-cavekit,
      rtk-src,
      nix-lefthook-git-conflict-markers,
      nix-lefthook-git-no-local-paths,
      nix-lefthook-markdownlint,
      nix-lefthook-missing-final-newline,
      nix-lefthook-nix-no-embedded-shell,
      nix-lefthook-trailing-whitespace,
      nix-lefthook-statix,
      nix-lefthook-taplo,
      nix-lefthook-unicode-lint,
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
      baseCiPackagesFor =
        pkgs:
        let
          inherit (pkgs.stdenv.hostPlatform) system;
          batsWithLibs = pkgs.bats.withLibraries (p: [
            p.bats-support
            p.bats-assert
            p.bats-file
          ]);
        in
        [
          nix-lefthook-git-conflict-markers.packages.${system}.default
          nix-lefthook-git-no-local-paths.packages.${system}.default
          nix-lefthook-markdownlint.packages.${system}.default
          nix-lefthook-missing-final-newline.packages.${system}.default
          nix-lefthook-nix-no-embedded-shell.packages.${system}.default
          nix-lefthook-trailing-whitespace.packages.${system}.default
          nix-lefthook-statix.packages.${system}.default
          nix-lefthook-taplo.packages.${system}.default
          nix-lefthook-unicode-lint.packages.${system}.default
          batsWithLibs
          pkgs.coreutils
          pkgs.deadnix
          pkgs.editorconfig-checker
          pkgs.git
          pkgs.lefthook
          pkgs.markdownlint-cli
          pkgs.nix
          pkgs.nixfmt
          pkgs.parallel
          pkgs.shellcheck
          pkgs.shfmt
          pkgs.typos
          pkgs.yamllint
        ];
    in
    {
      lib.mkShells =
        {
          pkgs,
          ciPackages ? [ ],
          shellHook ? "",
          extraDevPackages ? [ ],
        }:
        let
          inherit (pkgs.stdenv.hostPlatform) system;
          allCiPackages = (baseCiPackagesFor pkgs) ++ ciPackages;
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
            inherit shellHook;
          };
        };

      packages = forAllSystems (pkgs: {
        rtk = rtkFor pkgs;
      });

      templates.default = {
        path = ./template;
        description = "Nix project with agentic dev shell, CI split, lefthook, and vulnix scan";
      };

      devShells = forAllSystems (
        pkgs:
        let
          inherit (pkgs.stdenv.hostPlatform) system;
          ciPackages = baseCiPackagesFor pkgs;
        in
        {
          ci = pkgs.mkShell {
            packages = ciPackages;
          };
          default = pkgs.mkShell {
            packages = ciPackages ++ [
              nix-cavemem.packages.${system}.default
              nix-cavekit.packages.${system}.default
              (rtkFor pkgs)
              pkgs.gh
              pkgs.nodejs
            ];
            shellHook = ''
              export NIX_CONFIG="experimental-features = nix-command flakes"
              [ -f .git/hooks/pre-commit ] || lefthook install
            '';
          };
        }
      );
    };
}
