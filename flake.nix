{
  description = "nix-search — search installed packages across all NixOS scopes";

  inputs.nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";

  outputs = { self, nixpkgs }:
    let
      systems = [ "x86_64-linux" "aarch64-linux" ];
      forAllSystems = f: nixpkgs.lib.genAttrs systems (system: f system);
    in
    {
      packages = forAllSystems (system:
        let pkgs = nixpkgs.legacyPackages.${system};
        in {
          default = pkgs.writeShellScriptBin "nix-search" (builtins.readFile ./nix-search.sh);
        });

      # NixOS module — allows using nix-search as a NixOS module
      nixosModules.default = { pkgs, ... }: {
        environment.systemPackages = [
          (pkgs.writeShellScriptBin "nix-search" (builtins.readFile ./nix-search.sh))
        ];
      };
    };
}
