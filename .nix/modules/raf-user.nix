{ pkgs, ... }:
{
  # Define a user account. Don't forget to set a password with `passwd`.
  users.users.raf = {
    isNormalUser = true;
    description = "raf";
    extraGroups = [ "wheel" ];
    openssh.authorizedKeys.keys = [
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAINoK0Yz0b6ktXjUpbt9gtMwFI5jDHNrXfhUWzKekBvar bachourian@gmail.com"
    ];
    packages = with pkgs; [
      # TODO: use packages template
      git
      neovim
      ghostty
      nushell
      lazygit
      carapace
      zoxide
      starship
      tlrc
      bat
      tree-sitter
      nerd-fonts.jetbrains-mono
      nodejs_24
      bws
      chezmoi
      gcc
      gh
      ripgrep
      fd
      unzip
      cargo
      statix
      nixfmt
      topiary
      jujutsu
      fzf
      zellij
      gemini-cli
      opencode
      codex
      direnv
      vesktop
      jjui
      amnezia-vpn
      plex-desktop
      telegram-desktop
    ];
  };

  xdg.portal = {
    enable = true;
    extraPortals = [ pkgs.xdg-desktop-portal-gtk ];
    xdgOpenUsePortal = true;
  };

  services.tailscale = {
    enable = true;
    # Enable tailscale at startup
    # use tailscale login
  };

  environment.shells = [
    pkgs.nushell
  ];

  programs.niri.enable = true;
  security.polkit.enable = true; # polkit
  services.gnome.gnome-keyring.enable = true; # secret service

  programs.bash.interactiveShellInit = ''
    if ! [ "$TERM" = "dumb" ] && [ -z "$BASH_EXECUTION_STRING" ]; then
      exec nu
    fi
  '';

  environment.systemPackages = with pkgs; [
    git
    neovim
    uv
    ghostty
    fuzzel
    xwayland-satellite # xwayland support
    noctalia-shell
  ];

  programs.nix-ld.libraries = with pkgs; [
    # Add any missing dynamic libraries for unpackaged programs
    # here, NOT in environment.systemPackages
    stylua
  ];
}
