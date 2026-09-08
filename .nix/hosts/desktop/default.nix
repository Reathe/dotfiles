{
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

  # Ensure X11 is disabled.
  services.xserver.enable = false;
  services.xserver.videoDrivers = [ "nvidia" ]; # Required for NVIDIA kernel modules

  hardware.nvidia = {
    modesetting.enable = true;
    powerManagement.enable = true;
    open = false;
  };
  hardware.graphics.enable = true;

  hardware.bluetooth = {
    enable = true;
    powerOnBoot = true;
    settings = {
      General = {
        # Shows battery charge of connected devices on supported
        # Bluetooth adapters. Defaults to 'false'.
        Experimental = true;
        # When enabled other devices can connect faster to us, however
        # the tradeoff is increased power consumption. Defaults to
        # 'false'.
        FastConnectable = true;
      };
    };
  };
  hardware.xone.enable = true; # support for the xbox controller USB dongle

  # Enable CUPS to print documents.
  services.printing.enable = true;

  services.udisks2.enable = true;
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
