{ pkgs ? import <nixpkgs> {} }:

pkgs.writeShellScriptBin "nix-search" (builtins.readFile ./nix-search.sh)
