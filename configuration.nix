# Edit this configuration file to define what should be installed on
# your system.  Help is available in the configuration.nix(5) man page
# and in the NixOS manual (accessible by running ‘nixos-help’).
{pkgs, ...}: {
  imports = [
    # Include the results of the hardware scan.
    ./hardware-configuration.nix
    ./font.nix
    ./nix.nix
    ./printing.nix
    ./modules
    ./overlays
  ];

  # Bootloader.
  boot.loader = {
    grub = {
      enable = true;
      device = "nodev";
      efiSupport = true;
      splashImage = null;
      configurationLimit = 10;
      theme = "${
        (pkgs.fetchFromGitHub {
          owner = "xenlism";
          repo = "Grub-themes";
          rev = "40ac048df9aacfc053c515b97fcd24af1a06762f";
          hash = "sha256-ProTKsFocIxWAFbYgQ46A+GVZ7mUHXxZrvdiPJqZJ6I=";
        })
      }/xenlism-grub-2k-nixos/Xenlism-Nixos/";
    };
    efi = {
      canTouchEfiVariables = true;
      efiSysMountPoint = "/boot";
    };
  };

  # Enable "Silent boot"
  boot = {
    consoleLogLevel = 3;
    initrd.verbose = false;
    kernelParams = [
      "quiet"
      "splash"
      "boot.shell_on_fail"
      "udev.log_priority=3"
      "rd.systemd.show_status=auto"
    ];
  };

  # Use latest kernel.
  boot.kernelPackages = pkgs.linuxPackages_latest;

  networking.hostName = "ASUS"; # Define your hostname.
  # networking.wireless.enable = true;  # Enables wireless support via wpa_supplicant.

  # Configure network proxy if necessary
  # networking.proxy.default = "http://user:password@proxy:port/";
  # networking.proxy.noProxy = "127.0.0.1,localhost,internal.domain";

  # Enable networking
  networking.networkmanager.enable = true;

  # Set your time zone.
  time.timeZone = "Asia/Shanghai";

  # Select internationalisation properties.
  i18n.defaultLocale = "zh_CN.UTF-8";

  i18n.extraLocaleSettings = {
    LC_ADDRESS = "zh_CN.UTF-8";
    LC_IDENTIFICATION = "zh_CN.UTF-8";
    LC_MEASUREMENT = "zh_CN.UTF-8";
    LC_MONETARY = "zh_CN.UTF-8";
    LC_NAME = "zh_CN.UTF-8";
    LC_NUMERIC = "zh_CN.UTF-8";
    LC_PAPER = "zh_CN.UTF-8";
    LC_TELEPHONE = "zh_CN.UTF-8";
    LC_TIME = "zh_CN.UTF-8";
  };

  i18n.inputMethod = {
    type = "fcitx5";
    enable = true;
    fcitx5.waylandFrontend = true;
    fcitx5.addons = with pkgs; [
      fcitx5-rime
      fcitx5-gtk
      fcitx5-mellow-themes
      fcitx5-configtool
    ];
  };

  # Enable the KDE Plasma Desktop Environment.
  services.desktopManager.plasma6.enable = true;

  environment.plasma6.excludePackages = with pkgs.kdePackages; [
    elisa
    okular
    sddm-kcm
    ksystemlog
    xdg-desktop-portal-kde
  ];

  hardware.graphics = {
    enable = true;
    enable32Bit = true;
  };

  hardware.i2c.enable = true;

  # DDC/CI for monitor control
  services.udev.extraRules = ''
    KERNEL=="i2c-[0-9]-*", SUBSYSTEM=="i2c-dev", GROUP="i2c", MODE="0660"
  '';

  # Enable polkit for KDE Plasma
  # security.polkit.enable = true;

  # systemd.user.services.polkit-kde-authentication-agent = {
  #   description = "Polkit KDE Authentication Agent";
  #   wantedBy = [ "graphical-session.target" ];
  #   wants = [ "graphical-session.target" ];
  #   after = [ "graphical-session.target" ];
  #   serviceConfig = {
  #     Type = "simple";
  #     ExecStart = "${pkgs.kdePackages.polkit-kde-agent-1}/libexec/polkit-kde-authentication-agent-1";
  #     Restart = "on-failure";
  #     RestartSec = "1";
  #     TimeoutStopSec = "5";
  #   };
  # };

  # Configure keymap in X11
  services.xserver.xkb = {
    layout = "us";
    variant = "";
  };

  # Enable Bluetooth
  hardware.bluetooth.enable = true;
  hardware.bluetooth.powerOnBoot = true;

  # Enable Thunderbolt support
  services.hardware.bolt.enable = true;

  # Enable sound with pipewire.
  services.pulseaudio.enable = false;
  security.rtkit.enable = true;
  services.pipewire = {
    enable = true;
    alsa.enable = true;
    alsa.support32Bit = true;
    pulse.enable = true;
    # If you want to use JACK applications, uncomment this
    #jack.enable = true;

    # use the example session manager (no others are packaged yet so this is enabled by default,
    # no need to redefine it in your config for now)
    #media-session.enable = true;
  };

  # Enable touchpad support (enabled default in most desktopManager).
  # services.xserver.libinput.enable = true;

  environment.sessionVariables = {
    # this is a lazy way to do it. it works because
    # user vars come after setting this dummy var to 1.
    __NIXOS_SET_ENVIRONMENT_DONE = "";

    NIXOS_OZONE_WL = "1";

    XDG_CACHE_HOME = "$HOME/.cache";
    XDG_CONFIG_HOME = "$HOME/.config";
    XDG_DATA_HOME = "$HOME/.local/share";
    XDG_STATE_HOME = "$HOME/.local/state";
    PATH = ["$HOME/.local/bin"];
    ZDOTDIR = "$XDG_CONFIG_HOME/zsh";

    # set to nano by default
    # TODO find out where
    # EDITOR = "";

    # allows using $PAGER as the pager for systemctl commands
    SYSTEMD_PAGERSECURE = "false";
  };

  # Define a user account. Don't forget to set a password with ‘passwd’.
  users.users.zh = {
    isNormalUser = true;
    description = "zh";
    extraGroups = [
      "networkmanager"
      "wheel"
      "docker"
      "i2c"
      "input"
      "uinput"
    ];
    shell = pkgs.zsh;
  };

  # Install zsh.
  programs.zsh.enable = true;

  # Enable nix ld.
  nix-ld.enable = true;

  steam = {
    enable = true;
    enableNative = true; # Enable native Steam client.
    enableSteamBeta = true; # Enable Steam Beta client.
    fixDownloadSpeed = true; # Fix slow download speeds in Steam.
  };

  heroic = {
    enable = true; # Enable Heroic Games Launcher.
    enableNative = true; # Enable native Heroic client.
  };
  
  bottles = {
    enable = true; # Enable Bottles.
    enableNative = true; # Enable native Bottles.
    enableFlatpak = false; # Enable Bottles Flatpak version.
  };

  flatpak.enable = true; # Enable Flatpak support.

  virtualization.enable = true;

  obs = {
    enable = true;
    enableFlatpak = false;
    enableNative = true;
    silenceOutput = true;
  };

  # Disable nano, as it is not needed.
  programs.nano.enable = false;

  # List packages installed in system profile. To search, run:
  # $ nix search wget
  environment.systemPackages = with pkgs; [
    git
    vim
    neovim
    wget
    curl
    htop
    eza
    bun
    uv
    gcc
    libdbusmenu # https://github.com/microsoft/vscode/issues/34510
    xsettingsd
    xorg.xrdb
    xdg-desktop-portal-gtk
  ];

  environment.variables.EDITOR = "neovim";

  services.kanata = {
    enable = true;
    package = pkgs.kanata;
    keyboards = {
      internalKeyboard = {
        extraDefCfg = "process-unmapped-keys yes";
        config = ''
          (defsrc
           caps
          )
          (defalias
           caps (tap-hold 150 150 esc lctl)
          )
          (deflayer base
           @caps
          )
        '';
      };
    };
  };

  # Enable fingerprint reader support
  services.fprintd = {
    enable = true;
    tod = {
      enable = true;
      driver = pkgs.libfprint-2-tod1-elan;
    };
  };

  # Some programs need SUID wrappers, can be configured further or are
  # started in user sessions.
  # programs.mtr.enable = true;
  # programs.gnupg.agent = {
  #   enable = true;
  #   enableSSHSupport = true;
  # };

  # List services that you want to enable:

  # Enable the OpenSSH daemon.
  # services.openssh.enable = true;

  # Open ports in the firewall.
  # networking.firewall.allowedTCPPorts = [ ... ];
  # networking.firewall.allowedUDPPorts = [ ... ];
  # Or disable the firewall altogether.
  # networking.firewall.enable = false;
  networking.firewall = {
    enable = true;
    trustedInterfaces = ["Mihomo"];
    checkReversePath = "loose";
    allowedTCPPortRanges = [
      {
        from = 1714;
        to = 1764;
      } # KDE Connect
    ];
    allowedUDPPortRanges = [
      {
        from = 1714;
        to = 1764;
      } # KDE Connect
    ];
  };

  # This value determines the NixOS release from which the default
  # settings for stateful data, like file locations and database versions
  # on your system were taken. It‘s perfectly fine and recommended to leave
  # this value at the release version of the first install of this system.
  # Before changing this value read the documentation for this option
  # (e.g. man configuration.nix or on https://nixos.org/nixos/options.html).
  system.stateVersion = "25.05"; # Did you read the comment?
}
