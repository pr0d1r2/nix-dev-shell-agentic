## §D — Description

nix-dev-shell-agentic is a Nix flake library and project template that provides a turnkey "agentic" development shell with a CI/dev split. It bundles agentic tools (cavemem for cross-agent persistent memory, cavekit for spec-driven development, and rtk for token-optimized CLI proxying) alongside a comprehensive suite of lefthook-based git hooks (nixfmt, statix, deadnix, shellcheck, shfmt, typos, yamllint, gitleaks, markdownlint, and more) into a single flake input. Consumer projects call `lib.mkShells` to get a lean `.#ci` shell for CI pipelines and a full `.#default` shell for local development, with pre-built binaries served via cachix. Target users are Nix-based projects that want standardized code quality enforcement and agentic tooling without duplicating boilerplate across repos.

## §V — Invariants

1. The flake must evaluate and `nix flake check` must pass on all four supported systems: `aarch64-darwin`, `x86_64-darwin`, `x86_64-linux`, `aarch64-linux`.
2. `nix build .#rtk` must succeed on all CI matrix platforms (ubuntu-latest, macos-latest, ubuntu-24.04-arm).
3. All lefthook pre-commit remote hooks must pass on staged files before commit is accepted.
4. All lefthook pre-push remote hooks must pass on push files before push is accepted.
5. Nix files must pass `nixfmt`, `statix`, and `deadnix --fail -L` checks.
6. Nix files must not contain embedded shell scripts unless listed in `.nix-embedded-shell-allowlist`.
7. EditorConfig enforced: UTF-8 charset, LF line endings, 2-space indentation, trailing whitespace trimmed, final newline inserted.
8. YAML files must pass `yamllint` (truthy check-keys disabled, line-length disabled).
9. Markdown files must pass `markdownlint` (MD013 line-length and MD060 disabled).
10. Shell scripts must pass `shellcheck` and `shfmt` formatting checks.
11. No typos in source files (`typos` linter).
12. No git conflict markers in committed files.
13. No local filesystem paths in git-tracked files.
14. `nixpkgs` input always follows `nixpkgs-lock/nixpkgs` to ensure reproducible pinning.
15. The `.#ci` shell contains only linting/CI packages; agentic tools (cavemem, cavekit, rtk, gh, nodejs) are exclusive to `.#default`.
16. The `nixConfig` block must include the pr0d1r2 cachix substituter and trusted public key.
17. macOS lint CI jobs run only on push and workflow_dispatch events, not on pull requests.

## §I — Interfaces

### Flake library function

```nix
lib.mkShells {
  pkgs : Nixpkgs package set;
  inputs : Flake inputs attrset (lefthook packages auto-discovered from nix-lefthook-* inputs);
  ciPackages ? [] : List of extra packages for the CI shell;
  shellHook ? "" : Extra shell hook appended to the default hook;
  extraDevPackages ? [] : List of extra packages for the dev shell only;
} -> {
  ci : mkShell derivation (CI-only packages);
  default : mkShell derivation (CI + agentic + extra dev packages);
  batsWithLibs : bats with bats-support, bats-assert, bats-file;
}
```

### Flake outputs

| Output | Description |
|--------|-------------|
| `lib.mkShells` | Shell constructor function (see above) |
| `packages.<system>.rtk` | RTK CLI binary built from source |
| `overlays.lefthook` | Overlay re-exported from nix-lefthook |
| `templates.default` | Project template (path: `./template`) |
| `devShells.<system>.ci` | CI shell for this repo |
| `devShells.<system>.default` | Dev shell for this repo |

### Environment variables

| Variable | Set by | Purpose |
|----------|--------|---------|
| `NIX_CONFIG` | shellHook | Enables `nix-command flakes` experimental features |
| `BATS_LIB_PATH` | ci shell | Path to bats helper libraries |
| `LEFTHOOK_DEADNIX_TIMEOUT` | user | Timeout for deadnix hook (default: 30s) |
| `LEFTHOOK_NIX_FLAKE_CHECK_TIMEOUT` | user | Timeout for nix flake check hook (default: 300s in CI) |
| `RUSQLITE_USE_PKG_CONFIG` | rtk build | Forces rusqlite to use system sqlite via pkg-config |
| `RTK_DB_PATH` | rtk tests | Database path for RTK test suite |

### Configuration files

| File | Format | Purpose |
|------|--------|---------|
| `.nix-embedded-shell-allowlist` | Newline-delimited paths | Files exempt from no-embedded-shell check |
| `.markdownlint.yml` | YAML | Markdownlint rule overrides |
| `.yamllint.yml` | YAML | Yamllint rule overrides |
| `.editorconfig` | INI | Editor formatting rules |
| `.rtk/filters.toml` | TOML | RTK filter configuration (schema_version 1) |
| `lefthook.yml` | YAML | Git hook definitions and remote hook sources |
| `.envrc` | Shell | direnv integration (`use flake`) |

### CI workflows

| Workflow | Trigger | Jobs |
|----------|---------|------|
| `ci.yml` | push to main, PR to main, dispatch | lint-linux, lint-macos, build (matrix: ubuntu + macos), build-linux-arm |
| `update-pins.yml` | daily at 03:30 UTC, dispatch | Update nixpkgs-lock pin and open PR |

### Template CLI usage

```bash
nix flake init -t github:pr0d1r2/nix-dev-shell-agentic
```

## §T — Tasks

| status | id | goal |
|--------|----|------|
| `.` | T1 | Add bats tests for `mkShells` output structure (verify ci/default shells contain expected packages) |
| `.` | T2 | Add a LICENSE file (README states MIT but no LICENSE file exists) |
| `.` | T3 | Dogfood `mkShells` in the root flake's own `devShells` instead of duplicating the package list |
| `.` | T4 | Align `update-pins.yml` action versions with `ci.yml` (checkout@v4 -> v6, install-nix-action@v27 -> v31) |
| `.` | T5 | Add `.markdownlint.yml`, `.yamllint.yml`, and `.editorconfig` to the template directory |
| `.` | T6 | Add cachix integration to the template CI workflow for faster builds |
| `.` | T7 | Populate `.rtk/filters.toml` with default filter rules or document the expected format |
| `.` | T8 | Add a CLAUDE.md with project-specific conventions for agentic contributors |
| `.` | T9 | Resolve the lefthook wrapper/remote mismatch: root lefthook.yml defines 12 remotes but `lefthookWrappersFor` builds 20 wrappers — ensure consistency |
| `.` | T10 | Pin the nix-lefthook-ci-action in `ci.yml` to a tagged release instead of a bare commit SHA for readability |

## §B — Bugs / Known Issues

1. **Action version drift in `update-pins.yml`**: Uses `actions/checkout@v4` and `cachix/install-nix-action@v27` while `ci.yml` uses `@v6` and `@v31` respectively. The older versions may miss security fixes or features.

2. **Root flake does not dogfood `mkShells`**: The root `devShells` manually assembles package lists (`baseCiPackagesFor ++ lefthookWrappersFor ++ [...]`) instead of calling its own `lib.mkShells`. This means the library's own dev environment can diverge from what consumers get.

3. **Duplicate deadnix execution**: The root `lefthook.yml` defines local `deadnix` commands for both pre-commit and pre-push, while also pulling in the `nix-lefthook-deadnix` remote hook via `lefthookWrappersFor`. This may cause deadnix to run twice on the same files.

4. **Template references vulnix-scan but it is not packaged**: The template's `lefthook.yml` includes a `nix-lefthook-vulnix-scan` remote, and the template CI copies `.vulnix-whitelist-system.example.toml`. However, neither the root flake nor `mkShells` includes vulnix in the package set, so consumers relying on the library shell alone will lack the vulnix binary.

5. **`nix-lefthook-nix-no-embedded-shell` wrapper is inconsistent**: Unlike all other wrappers that use the `wrap` helper, this one manually constructs a `writeShellApplication` with an inline `SCANNER` variable prepended. This makes it fragile to changes in the upstream script's interface.

6. **Missing LICENSE file**: The README declares MIT license but no LICENSE or COPYING file exists in the repository.

7. **Template `flake.nix` has placeholder description**: `description = "CHANGEME"` is easy to forget, and no CI check validates that it was changed.

8. **Wrapper/remote count mismatch**: `lefthookWrappersFor` builds 20 shell wrappers (including ascii-only, file-size-check, gitleaks, unicode-lint, execute-permissions, tdd-order-bats) but the root `lefthook.yml` only configures 12 remote hooks. The extra wrappers are built but never invoked by lefthook in this repo.
