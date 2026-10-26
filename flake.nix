{
  inputs = {
    nixpkgs.url = "nixpkgs/nixos-26.05";
    nixpkgs-unstable.url = "nixpkgs/nixos-unstable";
    spicetify-nix = {
      url = "github:Gerg-L/spicetify-nix";
      inputs.nixpkgs.follows = "nixpkgs-unstable";
    };
    zen-browser = {
      url = "github:0xc000022070/zen-browser-flake";
      inputs.nixpkgs.follows = "nixpkgs-unstable";
    };
    claude-desktop = {
      url = "github:nmcbride/claude-desktop-nix";
      inputs.nixpkgs.follows = "nixpkgs-unstable";
    };
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
      pkgs = nixpkgs.legacyPackages.${system};
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
      # `nix fmt` formats every tracked .nix file; `nix flake check` lints .nix (and evaluates the hosts)
      formatter.${system} = pkgs.nixfmt-tree;
      checks.${system}.statix = pkgs.runCommand "statix" { } ''
        ${pkgs.statix}/bin/statix check --config ${./.nix} ${./.nix}
        touch $out
      '';

      nixosConfigurations = {
        nixos = mkHost [
          inputs.claude-desktop.nixosModules.default
          ./.nix/hosts/desktop
        ];
      };
    };
}
