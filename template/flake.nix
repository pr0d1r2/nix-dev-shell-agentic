{
  description = "CHANGEME";

  nixConfig = {
    extra-substituters = [ "https://pr0d1r2.cachix.org" ];
    extra-trusted-public-keys = [ "pr0d1r2.cachix.org-1:NfWjbhgAj41byXhCKiaE+av3Vnphm1fTezHXEGsiQIM=" ];
  };

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-25.11";
    nix-dev-shell-agentic = {
      url = "github:pr0d1r2/nix-dev-shell-agentic";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    nix-lefthook-vulnix-scan = {
      url = "github:pr0d1r2/nix-lefthook-vulnix-scan";
      inputs.nixpkgs.follows = "nixpkgs";
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
  };

  outputs =
    {
      nixpkgs,
      nix-dev-shell-agentic,
      nix-lefthook-vulnix-scan,
      nix-lefthook-git-conflict-markers,
      nix-lefthook-git-no-local-paths,
      nix-lefthook-missing-final-newline,
      nix-lefthook-nix-no-embedded-shell,
      nix-lefthook-trailing-whitespace,
      nix-lefthook-statix,
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
    in
    {
      devShells = forAllSystems (
        pkgs:
        let
          inherit (pkgs.stdenv.hostPlatform) system;
        in
        nix-dev-shell-agentic.lib.mkShells {
          inherit pkgs;
          ciPackages = [
            nix-lefthook-vulnix-scan.packages.${system}.default
            nix-lefthook-git-conflict-markers.packages.${system}.default
            nix-lefthook-git-no-local-paths.packages.${system}.default
            nix-lefthook-missing-final-newline.packages.${system}.default
            nix-lefthook-nix-no-embedded-shell.packages.${system}.default
            nix-lefthook-trailing-whitespace.packages.${system}.default
            nix-lefthook-statix.packages.${system}.default
            pkgs.coreutils
            pkgs.deadnix
            pkgs.editorconfig-checker
            pkgs.git
            pkgs.lefthook
            pkgs.nix
            pkgs.nixfmt
            pkgs.shellcheck
            pkgs.shfmt
            pkgs.typos
            pkgs.yamllint
          ];
          shellHook = ''
            export NIX_CONFIG="experimental-features = nix-command flakes"
            [ -f .git/hooks/pre-commit ] || lefthook install
          '';
        }
      );
    };
}
