{ ... }:
{
  # Edit this configuration file to define what should be installed on
  # your system. Help is available in the configuration.nix(5) man page
  # and in the NixOS manual (accessible by running `nixos-help`).
  imports = [
    ../../modules/common.nix
    ../../modules/raf-user.nix
    ./hardware-configuration.nix
  ];

  # Bootloader.
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  # Define your hostname.
  networking.hostName = "nixos";

  # Enable networking
  networking.networkmanager.enable = true;

  users.users.raf.extraGroups = [ "networkmanager" ];

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

    # If you want to use JACK applications, uncomment this
    # jack.enable = true;

    # Use the example session manager (no others are packaged yet so this
    # is enabled by default, no need to redefine it in your config for now)
    # media-session.enable = true;
  };

  # Enable kanata
  services.kanata = {
    enable = true;
    keyboards.vm.configFile = ../../../.chezmoitemplates/kanata.kbd;
  };

  # Install firefox.
  programs.firefox.enable = true;

  # This value determines the NixOS release from which the default
  # settings for stateful data, like file locations and database versions
  # on your system were taken. It's perfectly fine and recommended to
  # leave this value at the release version of the first install of this
  # system. Before changing this value read the documentation for this
  # option (e.g. man configuration.nix or on https://nixos.org/nixos/options.html).
  system.stateVersion = "25.11";
}
