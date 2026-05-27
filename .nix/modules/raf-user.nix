{ pkgs, inputs, ... }:
{
  # Define a user account. Don't forget to set a password with `passwd`.
  users.users.raf = {
    isNormalUser = true;
    description = "raf";
    extraGroups = [
      "wheel"
    ];
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
      plex-desktop
      telegram-desktop
      anydesk
      piper
      proton-vpn
      ollama-cuda
      lmstudio
      libreoffice
      yazi
      inputs.nix-software-center.packages.${system}.nix-software-center
    ];
  };

  programs = {
    niri.enable = true;
    amnezia-vpn.enable = true;
    steam = {
      enable = true;
      remotePlay.openFirewall = true; # Open ports in the firewall for Steam Remote Play
      dedicatedServer.openFirewall = true; # Open ports in the firewall for Source Dedicated Server
      localNetworkGameTransfers.openFirewall = true; # Open ports in the firewall for Steam Local Network Game Transfers
    };
    nix-ld.libraries = with pkgs; [
      # Add any missing dynamic libraries for unpackaged programs
      # here, NOT in environment.systemPackages
      stylua
    ];
    bash.interactiveShellInit = ''
      if ! [ "$TERM" = "dumb" ] && [ -z "$BASH_EXECUTION_STRING" ]; then
        exec nu
      fi
    '';

    dms-shell = {
      enable = true;

      systemd = {
        enable = true; # Systemd service for auto-start
        restartIfChanged = true; # Auto-restart dms.service when dms-shell changes
      };

      # Core features
      enableSystemMonitoring = true; # System monitoring widgets (dgop)
      enableVPN = true; # VPN management widget
      enableDynamicTheming = true; # Wallpaper-based theming (matugen)
      enableAudioWavelength = true; # Audio visualizer (cava)
      enableCalendarEvents = true; # Calendar integration (khal)
      enableClipboardPaste = true; # Pasting from the clipboard history (wtype)
    };
  };

  services = {
    ratbagd.enable = true; # for logitech mouse
    tailscale = {
      enable = true;
      # Enable tailscale at startup
      # use tailscale login
    };
    gnome.gnome-keyring.enable = true; # secret service
    displayManager.dms-greeter = {
      enable = true;
      compositor = {
        name = "niri"; # Or "hyprland" or "sway"
        customConfig = ''
          output "DP-6" {
              mode "1920x1080@60"
              focus-at-startup
              scale 1
              transform "normal"
              position x=0 y=0
          }
          hotkey-overlay {
              skip-at-startup
          }
        '';
      };
      # Sync your user's DankMaterialShell theme with the greeter. You'll probably want this
      configHome = "/home/raf";
    };
  };

  environment = {
    systemPackages = with pkgs; [
      git
      neovim
      uv
      ghostty
      xwayland-satellite # xwayland support
      papirus-icon-theme
      phinger-cursors
      inputs.zen-browser.packages.${pkgs.stdenv.hostPlatform.system}.default
    ];

    variables = {
    };
    shells = [
      pkgs.nushell
    ];
  };

  xdg.portal = {
    enable = true;
    #xdgOpenUsePortal = true;
    extraPortals = [
      pkgs.xdg-desktop-portal-gtk
    ];
  };
  security.polkit.enable = true; # polkit
}
