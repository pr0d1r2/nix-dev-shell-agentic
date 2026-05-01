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
  };

  outputs =
    {
      nixpkgs,
      nix-cavemem,
      nix-cavekit,
      rtk-src,
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
          nixpkgs.lib.filterAttrs (name: _: nixpkgs.lib.hasPrefix "nix-lefthook-" name) inputs
        );
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
            (lefthookPackagesFrom inputs system) ++ (baseCiPackagesFor pkgs) ++ [ batsWithLibs ] ++ ciPackages;
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
          packages = baseCiPackagesFor pkgs;
        };
        default = pkgs.mkShell {
          packages = (baseCiPackagesFor pkgs) ++ [
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
