{
  inputs = {
    nixpkgs.url = "nixpkgs/nixos-26.05";
    spicetify-nix.url = "github:Gerg-L/spicetify-nix";
    zen-browser = {
      url = "github:youwen5/zen-browser-flake";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    nix-software-center.url = "github:snowfallorg/nix-software-center";
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
          specialArgs = {
            inherit inputs;
          };
          modules = [
            {
              nixpkgs.hostPlatform = "x86_64-linux";
            }
          ] ++ modules;
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
