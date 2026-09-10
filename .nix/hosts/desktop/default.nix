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
  boot.loader.systemd-boot.configurationLimit = 10;
  boot.loader.systemd-boot.extraEntries = {
    "omarchy.conf" = ''
      title Omarchy (Limine)
      efi   /EFI/limine/limine.efi
      sort-key 10
    '';
    "revios.conf" = ''
      title ReviOS
      efi   /EFI/Microsoft/Boot/bootmgfw.efi
      sort-key 05
    '';
  };
  boot.loader.systemd-boot.extraFiles = {
    "EFI/limine/limine.efi" = "${pkgs.limine}/share/limine/BOOTX64.EFI";
    "EFI/limine/limine.conf" = pkgs.writeText "limine.conf" ''
      timeout: 0

      /Omarchy
          protocol: efi_chainload
          image_path: fslabel(OMARCHY_EFI):/EFI/limine/limine_x64.efi
    '';
  };
  nix.gc = {
    automatic = true;
    dates = "weekly";
    options = "--delete-older-than 30d";
  };

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
  systemd.services.kanata-desktop.serviceConfig = {
    Restart = "on-failure";
    RestartSec = "5s";
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
