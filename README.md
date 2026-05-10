# nix-search

A simple but powerful Bash utility to search and inspect installed packages across all scopes of a NixOS system.

```
nix-search -a global -k xfce
nix-search -a global,user --count
nix-search --duplicates
```

## Why?

On NixOS, packages can live in several different places:

- System-wide via `configuration.nix`
- Per-user via `nix-env` or user profiles
- Via Home Manager

There is no single command to see all of them at once, filter by keyword, or detect duplicates across scopes. `nix-search` solves that.

This tool is aimed at **NixOS newcomers** who are still getting familiar with the system and want a simple way to see what is installed and where.

## Features

- 🔍 Search across all scopes at once or pick specific ones
- 🔑 Keyword filtering to find exactly what you are looking for
- 👥 Multi-user aware — scans all users and their Home Manager installations
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

### Option 2 — configuration.nix (system-wide, non-flake)

Add directly to your `configuration.nix` to make it available for all users:

```nix
environment.systemPackages = [
  (import (builtins.fetchTarball "https://github.com/manelinux/nix-search/archive/refs/heads/main.tar.gz") {})
];
```

Then rebuild:

```bash
sudo nixos-rebuild switch
```

### Option 3 — nix-env (per-user, non-flake)

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
                Values: user, global, home-manager, all
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

# Show user-installed packages
nix-search -a user

# Search for xfce packages in the global system scope
nix-search -a global -k xfce

# Search across multiple scopes
nix-search -a global,user -k python

# Show all packages with count per scope
nix-search --count

# Find packages duplicated across scopes
nix-search --duplicates

# Find xfce-related duplicates
nix-search --duplicates -k xfce
```

## Example output

```
🔍 nix-search v2.2.0
   Scope:      global
   Keyword:    xfce
   Count:      no
   Duplicates: no

══════════════════════════════════════════
  🌐 GLOBAL SYSTEM PACKAGES (/run/current-system) (filtered by: 'xfce')
══════════════════════════════════════════
  1c299vsynd0vpbjzflbm4ynvjczrlcm0-xfce4-screensaver-4.20.1
  33bkjai3114vi9dkw4fb471w60hhkw4r-xfce4-pulseaudio-plugin-0.5.1
  flh2qmmzircss6qf1babnqbp8l0a1q13-xfce4-terminal-1.1.5
  fx0ffpy7258wlgqsc6a3cfmyh5y3w9bh-xfce4-panel-4.20.5
  ...
  ↳ Total: 17 package(s)
```

## Scopes

| Scope | Description |
|---|---|
| `user` | Packages installed via `nix-env` or user profiles, scans all users |
| `global` | System-wide packages from `/run/current-system` |
| `home-manager` | Packages managed by Home Manager, scans all users |
| `all` | All of the above |

## Uninstall

If installed via flake, remove it from your `flake.nix` and rebuild.

If installed via `configuration.nix`, remove the line and rebuild.

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
