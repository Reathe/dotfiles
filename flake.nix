{
  inputs = {
    nixpkgs.url = "nixpkgs/nixos-26.05";
    nixpkgs-unstable.url = "nixpkgs/nixos-unstable";
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
      nixpkgs-unstable,
      spicetify-nix,
      ...
    }:
    let
      system = "x86_64-linux";
      unstable = import nixpkgs-unstable {
        config = {
          allowUnfree = true;
        };
        inherit system;
      };
      mkHost =
        modules:
        nixpkgs.lib.nixosSystem {
          specialArgs = {
            inherit inputs unstable;
          };
          modules = [
            {
              nixpkgs.hostPlatform = "x86_64-linux";
            }
          ]
          ++ modules;
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
