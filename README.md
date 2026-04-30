# nix-dev-shell-agentic

[![CI](https://github.com/pr0d1r2/nix-dev-shell-agentic/actions/workflows/ci.yml/badge.svg)](https://github.com/pr0d1r2/nix-dev-shell-agentic/actions/workflows/ci.yml)

Nix flake library and template for agentic dev shells with CI/dev split.

Bundles agentic tools in one input — no more duplicating `nix/rtk.nix` and cave\* inputs across repos. Pre-built binaries served via [cachix](https://pr0d1r2.cachix.org).

## Bundled tools

| Tool | Source | Purpose |
|------|--------|---------|
| [cavemem](https://github.com/pr0d1r2/nix-cavemem) | flake input | Cross-agent persistent memory |
| [cavekit](https://github.com/pr0d1r2/nix-cavekit) | flake input | Spec-driven development toolkit |
| [rtk](https://github.com/rtk-ai/rtk) | built from source, cached via cachix | Token-optimized CLI proxy (60-90% savings) |
| git | nixpkgs | Version control |
| gh | nixpkgs | GitHub CLI |
| nodejs | nixpkgs | Node.js runtime |

## Quick start

```bash
mkdir my-project && cd my-project && git init
nix flake init -t github:pr0d1r2/nix-dev-shell-agentic
direnv allow
```

This scaffolds a complete project with CI, lefthook hooks, vulnix scanning, and agentic dev shell — ready in 30 seconds.

## How it works

`mkShells` takes your CI packages and creates two shells:

- **`.#ci`** — CI shell with `ciPackages` only (linters, lefthook, etc.)
- **`.#default`** — dev shell with `ciPackages` + all agentic tools

```nix
{
  inputs.nix-dev-shell-agentic = {
    url = "github:pr0d1r2/nix-dev-shell-agentic";
    inputs.nixpkgs.follows = "nixpkgs";
  };

  outputs = { nix-dev-shell-agentic, ... }:
    devShells = forAllSystems (pkgs:
      nix-dev-shell-agentic.lib.mkShells {
        inherit pkgs;
        ciPackages = [ /* linters, lefthook, vulnix-scan */ ];
        extraDevPackages = [ /* project-specific dev tools */ ];
        shellHook = ''
          [ -f .git/hooks/pre-commit ] || lefthook install
        '';
      }
    );
}
```

## Template contents

| File | Purpose |
|------|---------|
| `flake.nix` | CI/dev split with standard lefthook and vulnix-scan inputs |
| `.envrc` | direnv flake integration |
| `.github/workflows/ci.yml` | Linux + macOS CI using `.#ci` shell |
| `lefthook.yml` | Standard remote hooks (nixfmt, shellcheck, shfmt, statix, deadnix, typos, yamllint, etc.) |
| `.claude/settings.json` | Claude Code permissions |
| `.gitignore` | result, .direnv, flake.lock |
| `.vulnix-whitelist-system.toml.example` | System whitelist stub for vulnix scan |

## Binary cache

RTK is built from source but cached via [cachix](https://pr0d1r2.cachix.org). Consumer flakes include `nixConfig` with the substituter, so `nix develop` pulls pre-built binaries instead of compiling.

To accept the cache without prompts, add to `~/.config/nix/nix.conf`:

```ini
trusted-substituters = https://pr0d1r2.cachix.org
trusted-public-keys = pr0d1r2.cachix.org-1:NfWjbhgAj41byXhCKiaE+av3Vnphm1fTezHXEGsiQIM=
```

## License

MIT
