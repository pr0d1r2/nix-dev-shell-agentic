{ pkgs, src }:
let
  cargoToml = pkgs.lib.trivial.importTOML "${src}/Cargo.toml";
in
pkgs.rustPlatform.buildRustPackage {
  pname = "rtk";
  inherit (cargoToml.package) version;

  inherit src;

  cargoLock.lockFile = "${src}/Cargo.lock";

  nativeBuildInputs = with pkgs; [
    pkg-config
    git
  ];

  buildInputs = with pkgs; [
    sqlite
  ];

  RUSQLITE_USE_PKG_CONFIG = "1";

  preCheck = ''
    HOME="$(mktemp -d)"
    export HOME
    export RTK_DB_PATH="$HOME/rtk-test.db"
  '';

  meta = with pkgs.lib; {
    description = "CLI proxy that reduces LLM token consumption by 60-90%";
    homepage = "https://github.com/rtk-ai/rtk";
    license = licenses.mit;
    mainProgram = "rtk";
  };
}
