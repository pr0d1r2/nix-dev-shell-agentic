{
  description = "Agentic Nix dev shell with CI/dev split";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-25.11";
    nix-cavemem = {
      url = "github:pr0d1r2/nix-cavemem";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs =
    {
      self,
      nixpkgs,
      nix-cavemem,
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
      lib.mkShells =
        {
          pkgs,
          ciPackages ? [ ],
          shellHook ? "",
          extraDevPackages ? [ ],
        }:
        let
          inherit (pkgs.stdenv.hostPlatform) system;
        in
        {
          ci = pkgs.mkShell {
            packages = ciPackages;
          };
          default = pkgs.mkShell {
            packages =
              ciPackages
              ++ [
                nix-cavemem.packages.${system}.default
                pkgs.nodejs
              ]
              ++ extraDevPackages;
            inherit shellHook;
          };
        };

      templates.default = {
        path = ./template;
        description = "Nix project with agentic dev shell, CI split, lefthook, and vulnix scan";
      };

      devShells = forAllSystems (pkgs: {
        default = pkgs.mkShell {
          packages = [
            nix-cavemem.packages.${pkgs.stdenv.hostPlatform.system}.default
            pkgs.nodejs
          ];
        };
      });
    };
}
