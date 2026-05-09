# nix-search
A Bash utility to search installed packages across all NixOS scopes

nix-search
A simple but powerful Bash utility to search and inspect installed packages across all scopes of a NixOS system — user environments, system-wide packages, Nix flake profiles, and Home Manager — all in one command.
Why?
On NixOS, packages can be installed in several different places:

System-wide via configuration.nix
Per-user via nix-env
Via Nix flake profiles
Via Home Manager

There's no single command to see all of them at once, filter by keyword, or detect duplicates across scopes. nix-search solves that.
Features

🔍 Search across all scopes at once or pick specific ones
🔑 Keyword filtering to find exactly what you're looking for
👥 Multi-user aware — scans all users' flake profiles and Home Manager installations
🔁 Duplicate detection — find packages installed in more than one scope
📊 Package count per scope
⚡ Fast and lightweight — pure Bash, no dependencies

Installation
Clone or download the repository, then run the installer:
bashgit clone https://github.com/yourusername/nix-search.git
cd nix-search
chmod +x install.sh
./install.sh
The installer will:

Copy nix-search to /usr/local/bin
Add /usr/local/bin to the global PATH in /etc/nixos/configuration.nix (if not already present)
Run nixos-rebuild switch automatically

After installation, nix-search is available system-wide for all users.
Usage
nix-search [options]

Options:
  -a, --ambit   <scope1,scope2,...>   Scopes to search (default: all)
                Values: user, global, flake, home-manager, all
  -k, --keyword <word>                Filter results by keyword (optional)
  -c, --count                         Show package count per scope
  -d, --duplicates                    Show only packages found in more than one scope
  -v, --version                       Show version
  -h, --help                          Show help

Note: The -a scope values are in Catalan (usuari, global, flake, home-manager, tots) in the current version. An English version is planned.

Examples
bash# Show all packages across all scopes
nix-search

# Show only user-installed packages
nix-search -a usuari

# Search for xfce packages in the global system scope
nix-search -a global -k xfce

# Search across multiple scopes
nix-search -a global,usuari -k python

# Show all packages with count per scope
nix-search --count

# Find packages duplicated across scopes
nix-search --duplicats

# Find xfce-related duplicates
nix-search --duplicats -k xfce


# Scopes explained

"usuari" - Packages installed via nix-env for the current user

"global" - System-wide packages from /run/current-system

"flake" - Per-user Nix flake profiles (scans all users)

"home-manager" - Packages managed by Home Manager (scans all users)

"tots" - All of the above

# Uninstall
sudo rm /usr/local/bin/nix-search

# Requirements

NixOS, Bash 4+, Standard NixOS tools (nix-env, nix-store)

# Contributing

Pull requests and issues are welcome! Some ideas for future improvements:

English scope names, JSON output (--json), --no-color flag for piping output, Show package versions alongside names

License
MIT
