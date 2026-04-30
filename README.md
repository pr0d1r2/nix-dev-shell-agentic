# nix-dev-shell-agentic

Nix flake library and template for agentic dev shells with CI/dev split.

Bundles [cavemem](https://github.com/pr0d1r2/nix-cavemem), Node.js, and provides `mkShells` to create paired CI and dev shells from a single package list.

## Quick start

```bash
mkdir my-project && cd my-project && git init
nix flake init -t github:pr0d1r2/nix-dev-shell-agentic
direnv allow
```

## Library usage

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
        shellHook = ''
          [ -f .git/hooks/pre-commit ] || lefthook install
        '';
      }
    );
}
```

This creates:
- `.#ci` — CI shell with `ciPackages` only
- `.#default` — dev shell with `ciPackages` + cavemem + Node.js

## Template contents

| File | Purpose |
|------|---------|
| `flake.nix` | CI/dev split with all standard lefthook inputs |
| `.envrc` | direnv flake integration |
| `.github/workflows/ci.yml` | Linux + macOS CI with `.#ci` shell |
| `lefthook.yml` | Standard remote hooks |
| `.claude/settings.json` | Claude Code permissions |
| `.gitignore` | result, .direnv, flake.lock |
| `.vulnix-whitelist-system.toml.example` | System whitelist stub |

## License

MIT
