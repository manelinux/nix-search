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
- Per-user via `nix-env`
- Via Nix flake profiles
- Via Home Manager

There is no single command to see all of them at once, filter by keyword, or detect duplicates across scopes. `nix-search` solves that.

## Features

- 🔍 Search across all scopes at once or pick specific ones
- 🔑 Keyword filtering to find exactly what you are looking for
- 👥 Multi-user aware — scans all users flake profiles and Home Manager installations
- 🔁 Duplicate detection — find packages installed in more than one scope
- 📊 Package count per scope
- ⚡ Fast and lightweight — pure Bash, no dependencies

## Installation

Clone or download the repository, then run the installer:

```bash
git clone https://github.com/manelinux/nix-search.git
cd nix-search
chmod +x install.sh
./install.sh
```

The installer will:

1. Copy `nix-search` to `/usr/local/bin`
2. Add `/usr/local/bin` to the global `PATH` in `/etc/nixos/configuration.nix` if not already present
3. Run `nixos-rebuild switch` automatically

After installation, `nix-search` is available system-wide for all users.

## Usage

```
nix-search [options]

Options:
  -a, --ambit   <scope1,scope2,...>   Scopes to search (default: all)
                Values: user, global, flake, home-manager, all
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

# Show only user-installed packages
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
🔍 nix-search v2.0.0
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
| `user` | Packages installed via `nix-env` for the current user |
| `global` | System-wide packages from `/run/current-system` |
| `flake` | Per-user Nix flake profiles, scans all users |
| `home-manager` | Packages managed by Home Manager, scans all users |
| `all` | All of the above |

## Uninstall

```bash
sudo rm /usr/local/bin/nix-search
```

## Requirements

- NixOS
- Bash 4+
- Standard NixOS tools (`nix-env`, `nix-store`)

## Contributing

Pull requests and issues are very welcome! Some ideas for future improvements:

- Wrap as a Nix flake for declarative installation
- JSON output with `--json`
- `--no-color` flag for piping output
- Show package versions alongside names

## License

MIT
