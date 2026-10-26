{
  pkgs,
  inputs,
  unstable,
  ...
}:
{
  # Define a user account. Don't forget to set a password with `passwd`.
  users.users.raf = {
    isNormalUser = true;
    description = "raf";
    extraGroups = [
      "wheel"
      "input" # evdev access for voxtype's push-to-talk hotkey watcher
    ];
    openssh.authorizedKeys.keys = [
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAINoK0Yz0b6ktXjUpbt9gtMwFI5jDHNrXfhUWzKekBvar bachourian@gmail.com"
    ];
    packages =
      (with pkgs; [
        # NixOS 26.05 (stable). Move a package to the unstable block below to use nixos-unstable instead.
        git
        ghostty
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
        stylua
        nix-search-tv
        television
        vesktop
        jjui
        plex-desktop
        telegram-desktop
        anydesk
        piper
        proton-vpn
        open-webui
        lmstudio
        libreoffice
        yazi
        kdePackages.dolphin
        pulseaudio # pactl only (pipewire-pulse is the server): the voxtype bar widget's mic bars need it
        jellyfin-desktop
        libnotify
      ])
      ++ (with unstable; [
        # nixos-unstable. Move a package here to get the unstable version instead of 26.05.
        neovim
        nushell
        carapace # unstable to match nushell: 26.05's carapace emits a completer nushell deprecated
        lazygit
        zellij
        opencode
        codex
        claude-code
        chromium
        google-chrome
        voxtype-vulkan
        cava
      ]);
  };

  programs = {
    nh = {
      enable = true;
      flake = "/home/raf/.local/share/chezmoi"; # NH_FLAKE, so `nh os switch` needs no path
      clean = {
        enable = true; # replaces nix.gc
        extraArgs = "--keep-since 30d --keep 5";
      };
    };
    claude-desktop = {
      enable = true;
      cowork.kvmUsers = [ "raf" ]; # /dev/kvm access for Cowork's micro-VM
    };
    niri.enable = true;
    direnv = {
      enable = true; # per-project envs from .envrc (hooked into nushell in config.nu)
      nix-direnv.enable = true; # cached `use flake` / `use nix`
    };
    amnezia-vpn.enable = true;
    steam = {
      enable = true;
      remotePlay.openFirewall = true; # Open ports in the firewall for Steam Remote Play
      dedicatedServer.openFirewall = true; # Open ports in the firewall for Source Dedicated Server
      localNetworkGameTransfers.openFirewall = true; # Open ports in the firewall for Steam Local Network Game Transfers
    };

    dms-shell = {
      enable = true;
      package = unstable.dms-shell;

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
    displayManager = {
      dms-greeter = {
        enable = true;
        package = unstable.dms-greeter;
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
      autoLogin = {
        enable = true;
        user = "raf";
      };
      defaultSession = "niri";
    };
    ollama = {
      enable = true;
      package = unstable.ollama-cuda.override {
        cudaArches = [ "86" ];
      };
    };
  };

  environment = {
    systemPackages =
      (with pkgs; [
        uv
        xwayland-satellite # xwayland support
        papirus-icon-theme
        phinger-cursors
        inputs.zen-browser.packages.${pkgs.stdenv.hostPlatform.system}.default
        kdePackages.qtsvg
      ])
      ++ (with unstable; [ ]);

    variables = {
      TERMINAL = "ghostty";
    };
  };

  environment.etc."xdg/kdeglobals".text = ''
    [General]
    TerminalApplication=ghostty
  '';

  xdg.portal = {
    enable = true;
    #xdgOpenUsePortal = true;
    extraPortals = [
      pkgs.xdg-desktop-portal-gtk
    ];
  };
  security.polkit.enable = true; # polkit
  security.pam.services.greetd.enableGnomeKeyring = true; # unlock keyring on login (greetd, not dms-greeter, does the actual user auth)

  systemd.user.services.voxtype = {
    description = "Voxtype push-to-talk voice-to-text daemon";
    wantedBy = [ "graphical-session.target" ];
    partOf = [ "graphical-session.target" ];
    serviceConfig = {
      # voxtype scans /dev/input/ once at startup and never rescans. kanata-desktop.service
      # (a system service) grabs the physical keyboard exclusively and re-emits through a
      # virtual "kanata" device, so voxtype must see that device in its initial scan — otherwise
      # once kanata later grabs the keyboard, the PAUSE hotkey stops reaching voxtype for good.
      ExecStartPre = "${pkgs.bash}/bin/bash -c 'for i in $(seq 1 100); do [ -e /run/kanata-desktop/desktop ] && exit 0; sleep 0.1; done; exit 0'";
      ExecStart = "${unstable.voxtype-vulkan}/bin/voxtype";
      Restart = "on-failure";
      # back off so a transient failure (e.g. config missing mid `chezmoi apply`) doesn't hit
      # the default 5-starts-in-10s limit and leave the daemon dead until a manual restart
      RestartSec = 5;
    };
  };
}
