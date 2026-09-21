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
      title Omarchy
      efi   /EFI/omarchy/refind_x64.efi
      sort-key 10
    '';
    "revios.conf" = ''
      title Windows (ReviOS)
      efi   /EFI/Microsoft/Boot/bootmgfw.efi
      sort-key 05
    '';
  };
  # systemd-boot can only load EFI binaries from its own ESP and Omarchy's is on the
  # other disk, so rEFInd bridges to its UKI, booting it immediately with no menu.
  # rEFInd leaves signature checks to the firmware. Limine and GRUB don't work here:
  # whenever the SecureBoot variable is set, Limine demands a blake2b hash for every
  # path (the UKI's changes on each Omarchy kernel update), and GRUB refuses to
  # chainload anything without shim.
  boot.loader.systemd-boot.extraFiles = {
    "EFI/omarchy/refind_x64.efi" = "${pkgs.refind}/share/refind/refind_x64.efi";
    "EFI/omarchy/refind.conf" = pkgs.writeText "refind.conf" ''
      timeout -1
      use_nvram false
      textonly
      hideui all
      scanfor manual
      default_selection Omarchy

      menuentry "Omarchy" {
          volume OMARCHY_EFI
          loader /EFI/Linux/omarchy_linux.efi
          options "cryptdevice=UUID=5babe784-4c25-42fd-ba8c-0e02ef0ec6b1:omarchy_root root=/dev/mapper/omarchy_root zswap.enabled=0 rootflags=subvol=@ rw rootfstype=btrfs resume=/dev/mapper/omarchy_root resume_offset=1931309 initramfs_async=0 quiet splash loglevel=0 systemd.show_status=false rd.udev.log_level=0 vt.global_cursor_default=0"
      }
    '';
  };

  # The Asmedia ASM107x hub on usb1 (1-5) regularly has a downstream device fail
  # to enumerate ("device descriptor read/64, error -110"); the kernel retries for
  # ~65s and the initrd udev worker handling usb1 stays stuck for the duration, so
  # switch-root waits out the full 90s stop timeout. Cap it -- stage 2 re-triggers
  # udev, so nothing is lost by killing the doomed worker early.
  boot.initrd.systemd.services.systemd-udevd = {
    overrideStrategy = "asDropin";
    serviceConfig.TimeoutStopSec = "30s";
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
