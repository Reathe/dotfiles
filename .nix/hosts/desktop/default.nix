{
  lib,
  inputs,
  pkgs,
  ...
}:
let
  spicePkgs = inputs.spicetify-nix.legacyPackages.${pkgs.stdenv.hostPlatform.system};
in
{
  imports = [
    ../../modules/common.nix
    ../../modules/raf-user.nix
    ./hardware-configuration.nix
    inputs.spicetify-nix.nixosModules.default
  ];

  # Define your hostname.
  networking.hostName = "nixos";

  # Bootloader.
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  # Enable networking.
  networking.networkmanager.enable = true;

  users.users.raf.extraGroups = [
    "networkmanager"
  ];

  # Enable the graphical desktop on the physical machine.
  services.xserver.enable = lib.mkForce true;
  services.displayManager.sddm.enable = lib.mkForce true;
  services.desktopManager.plasma6.enable = lib.mkForce true;

  services.xserver.videoDrivers = [ "nvidia" ];
  hardware.nvidia.modesetting.enable = true;
  hardware.nvidia.open = false;
  hardware.graphics.enable = true;

  # Enable CUPS to print documents.
  services.printing.enable = true;

  # Enable sound with pipewire.
  services.pulseaudio.enable = false;
  security.rtkit.enable = true;
  services.pipewire = {
    enable = true;
    alsa.enable = true;
    alsa.support32Bit = true;
    pulse.enable = true;
  };

  # Enable kanata.
  services.kanata = {
    enable = true;
    keyboards.desktop.configFile = ../../../.chezmoitemplates/kanata.kbd;
  };

  # Install firefox.
  programs.firefox.enable = true;

  programs.spicetify = {
    enable = true;
    wayland = true;
    enabledExtensions = with spicePkgs.extensions; [
      adblockify
      shuffle
    ];
  };

  # Keep the state version explicit per host.
  system.stateVersion = "25.11";
}
