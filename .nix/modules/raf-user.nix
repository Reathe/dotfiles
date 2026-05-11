{ pkgs, ... }:
{
  # Define a user account. Don't forget to set a password with `passwd`.
  users.users.raf = {
    isNormalUser = true;
    description = "raf";
    shell = pkgs.nushell;
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
      wezterm
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
      discord
      jjui
    ];
  };

  services.tailscale = {
    enable = true;
    # Enable tailscale at startup
    # use tailscale login
  };

  environment.systemPackages = with pkgs; [
    git
    neovim
    uv
  ];

  programs.nix-ld.libraries = with pkgs; [
    # Add any missing dynamic libraries for unpackaged programs
    # here, NOT in environment.systemPackages
    stylua
  ];
}
