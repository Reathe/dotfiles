{ ... }:
{
  # Set your time zone.
  time.timeZone = "Europe/Paris";

  # Select internationalisation properties.
  i18n.defaultLocale = "en_US.UTF-8";
  i18n.extraLocaleSettings = {
    LC_ADDRESS = "fr_FR.UTF-8";
    LC_IDENTIFICATION = "fr_FR.UTF-8";
    LC_MEASUREMENT = "fr_FR.UTF-8";
    LC_MONETARY = "fr_FR.UTF-8";
    LC_NAME = "fr_FR.UTF-8";
    LC_NUMERIC = "fr_FR.UTF-8";
    LC_PAPER = "fr_FR.UTF-8";
    LC_TELEPHONE = "fr_FR.UTF-8";
    LC_TIME = "fr_FR.UTF-8";
  };

  programs.nix-ld = {
    enable = true;
    libraries = [ ];
  };

  environment = {
    sessionVariables = {
      # localBinInPath = true; # doesnt work with nu
      XDG_CONFIG_HOME = "$HOME/.config";
      EDITOR = "nvim";
    };
  };

  # Allow unfree packages
  nixpkgs.config.allowUnfree = true;

  # List packages installed in system profile. To search, run:
  # $ nix search wget
  environment.systemPackages = [ ];
  # link packages' nushell completions (e.g. nh's) into the profiles nushell autoloads from
  environment.pathsToLink = [ "/share/nushell" ];

  nix = {
    settings = {
      experimental-features = [
        "nix-command"
        "flakes"
      ];
      # unfree CUDA builds (ollama-cuda) that cache.nixos.org doesn't carry; checked after it (priority 50 vs 40)
      substituters = [ "https://cache.nixos-cuda.org" ];
      trusted-public-keys = [
        "cache.nixos-cuda.org:74DUi4Ye579gUqzH4ziL9IyiJBlDpMRn9MBN8oNan9M="
      ];
    };
    optimise.automatic = true; # hard-link identical store files, daily (caught up after a night powered off)
  };

  # Enable the OpenSSH daemon.
  services.openssh = {
    enable = true;
    openFirewall = false; # reachable over Tailscale only, below
    settings = {
      PasswordAuthentication = false;
      KbdInteractiveAuthentication = false; # else PAM still asks for the password through it
      PermitRootLogin = "no";
    };
  };
  # not trustedInterfaces: that would open every port to the tailnet
  networking.firewall.interfaces.tailscale0.allowedTCPPorts = [ 22 ];
}
