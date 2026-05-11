# nix-search

A simple but powerful Bash utility to search and inspect installed packages across all scopes of a NixOS system.

```
nix-search -a global -k xfce
nix-search -a config -k gimp
nix-search -a global,user --count
nix-search --duplicates
```

## Why?

On NixOS, packages can live in several different places:

- Declared in `configuration.nix` (system-wide or per-user)
- Installed via `nix-env`
- Via Home Manager

There is no single command to see all of them at once, filter by keyword, or detect duplicates across scopes. `nix-search` solves that.

This tool is aimed at **NixOS newcomers** who are still getting familiar with the system and want a simple way to see what is installed and where.

## Features

- 🔍 Search across all scopes at once or pick specific ones
- 🔑 Keyword filtering to find exactly what you are looking for
- 👥 Multi-user aware — scans all users and their Home Manager installations
- 📋 Parses `configuration.nix` to show declared packages separately from runtime ones
- 🔁 Duplicate detection — find packages installed in more than one scope
- 📊 Package count per scope
- ⚡ Fast and lightweight — pure Bash, no dependencies

## Installation

### Option 1 — Nix Flake (recommended)

Add `nix-search` to your `flake.nix`:

```nix
{
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    nix-search.url = "github:manelinux/nix-search";
  };

  outputs = { nixpkgs, nix-search, ... }: {
    nixosConfigurations.myhost = nixpkgs.lib.nixosSystem {
      system = "x86_64-linux";
      modules = [
        ./configuration.nix
        nix-search.nixosModules.default
      ];
    };
  };
}
```

Then rebuild:

```bash
sudo nixos-rebuild switch --flake /etc/nixos#myhost
```

### Option 2 — nix-env (per-user, non-flake)

This option uses the included `default.nix` file, which tells Nix how to build and install `nix-search` without needing flakes.

Download and install from GitHub:

```bash
wget https://github.com/manelinux/nix-search/archive/refs/heads/main.tar.gz -O nix-search.tar.gz
tar -xzf nix-search.tar.gz
nix-env -i -f nix-search-main/
```

Or clone and install locally:

```bash
git clone https://github.com/manelinux/nix-search.git
nix-env -i -f nix-search/
```

## Usage

```
nix-search [options]

Options:
  -a, --scope   <scope1,scope2,...>   Scopes to search (default: all)
                Values: user, global, config, home-manager, all
  -k, --keyword <word>                Filter results by keyword
  -c, --count                         Show package count per scope
  -d, --duplicates                    Show only packages found in more than one scope
  -v, --version                       Show version
  -h, --help                          Show help
```

## Examples

```bash
# Show all packages across all scopes
nix-search

# Show packages declared in configuration.nix
nix-search -a config

# Show user-installed packages (nix-env)
nix-search -a user

# Search for xfce packages in the global system scope
nix-search -a global -k xfce

# Search across multiple scopes
nix-search -a global,config -k gtk

# Show all packages with count per scope
nix-search --count

# Find packages duplicated across scopes
nix-search --duplicates

# Find xfce-related duplicates
nix-search --duplicates -k xfce
```

## Example output

```
🔍 nix-search v2.5.0
   Scope:      config
   Keyword:    (none, showing all)
   Count:      no
   Duplicates: no

══════════════════════════════════════════
  📋 CONFIGURATION.NIX — environment.systemPackages
══════════════════════════════════════════
  wget
  curl
  vlc
  obs-studio
  ...

══════════════════════════════════════════
  👤 CONFIGURATION.NIX — users.users.alice.packages
══════════════════════════════════════════
  tree
  hexchat
  gimp
  audacity
  ...
```

## Scopes

| Scope | Description |
|---|---|
| `user` | Packages installed via `nix-env`, scans all users |
| `global` | All packages from `/run/current-system` (runtime) |
| `config` | Packages declared in `/etc/nixos/configuration.nix` |
| `home-manager` | Packages managed by Home Manager, scans all users |
| `all` | All of the above |

## Uninstall

If installed via flake, remove it from your `flake.nix` and rebuild.

If installed via nix-env:

```bash
nix-env -e nix-search
```

## Requirements

- NixOS
- Bash 4+
- Standard NixOS tools (`nix-env`, `nix-store`)

## Contributing

Pull requests and issues are very welcome! Some ideas for future improvements:

- JSON output with `--json`
- `--no-color` flag for piping output
- Show package versions alongside names

## License

MIT
