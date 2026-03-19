{
  inputs = {
    nixpkgs.url = "nixpkgs/nixos-25.11";
    nixpkgs-unstable.url = "nixpkgs/nixos-unstable";
  };

  outputs =
    { nixpkgs, nixpkgs-unstable, ... }:
    {
      nixosConfigurations.nixos = nixpkgs.lib.nixosSystem {
        modules = [
          ./configuration.nix
          {
            nixpkgs.overlays = [
              (final: prev: { inherit (nixpkgs-unstable.legacyPackages.${final.system}) lazygit; })
            ];
          }
        ];
      };
    };
}
