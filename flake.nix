{
  inputs = {
    nixpkgs.url = "nixpkgs/nixos-unstable";
    spicetify-nix.url = "github:Gerg-L/spicetify-nix";
  };

  outputs =
    inputs@{
      nixpkgs,
      spicetify-nix,
      ...
    }:
    let
      mkHost =
        modules:
        nixpkgs.lib.nixosSystem {
          system = "x86_64-linux";
          specialArgs = {
            inherit inputs;
          };
          inherit modules;
        };
    in
    {
      nixosConfigurations = {
        nixos = mkHost [
          ./.nix/hosts/desktop
        ];
      };
    };
}
