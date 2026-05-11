{
  inputs = {
    nixpkgs.url = "nixpkgs/nixos-25.11";
    nixpkgs-unstable.url = "nixpkgs/nixos-unstable";
    nixos-wsl.url = "github:nix-community/NixOS-WSL/main";
  };

  outputs =
    {
      nixpkgs,
      nixpkgs-unstable,
      nixos-wsl,
      ...
    }:
    let
      mkHost =
        modules:
        nixpkgs.lib.nixosSystem {
          system = "x86_64-linux";
          specialArgs = { inherit nixpkgs-unstable; };
          inherit modules;
        };
    in
    {
      nixosConfigurations = {
        nixos = mkHost [
          ./.nix/modules/unstable-overlay.nix
          ./.nix/hosts/desktop
        ];

        nixos-vm = mkHost [
          ./.nix/modules/unstable-overlay.nix
          ./.nix/hosts/vm
        ];

        nixos-wsl = mkHost [
          ./.nix/modules/unstable-overlay.nix
          nixos-wsl.nixosModules.default
          ./.nix/hosts/wsl
        ];
      };
    };
}
