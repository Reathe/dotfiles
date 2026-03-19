{ lib, ... }:
{
  # WSL reuses the shared desktop-agnostic base but keeps integration-
  # specific settings here so it can diverge from the VM cleanly.
  imports = [
    ../../modules/common.nix
    ../../modules/raf-user.nix
  ];

  # Define your hostname.
  networking.hostName = "nixos-wsl";
  networking.networkmanager.enable = lib.mkForce false;

  # Enable NixOS-WSL and make the shared user the default login.
  wsl.enable = true;
  wsl.defaultUser = "raf";

  # Disable services that do not make sense inside WSL.
  services.printing.enable = lib.mkForce false;
  services.kanata.enable = lib.mkForce false;
  services.pipewire.enable = lib.mkForce false;
  programs.firefox.enable = lib.mkForce false;

  # Keep the state version explicit per host.
  system.stateVersion = "25.11";
}
