{
  description = "Agentic Nix dev shell with CI/dev split";

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
      self,
      nixpkgs,
      nix-cavemem,
      nix-cavekit,
      rtk-src,
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
        in
        {
          default = pkgs.mkShell {
            packages = [
              nix-cavemem.packages.${system}.default
              nix-cavekit.packages.${system}.default
              (rtkFor pkgs)
              pkgs.gh
              pkgs.nodejs
            ];
          };
        }
      );
    };
}
