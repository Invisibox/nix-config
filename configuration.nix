# Edit this configuration file to define what should be installed on
# your system.  Help is available in the configuration.nix(5) man page
# and in the NixOS manual (accessible by running ‘nixos-help’).
{
  config,
  pkgs,
  inputs,
  ...
}: {
  imports = [
    # Include the results of the hardware scan.
    ./hardware-configuration.nix
    ./nix.nix
  ];

  # Bootloader.
  boot.loader = {
    grub = {
      enable = true;
      device = "nodev";
      efiSupport = true;
      configurationLimit = 10;
    };
    efi = {
      canTouchEfiVariables = true;
      efiSysMountPoint = "/boot";
    };
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
      kdePackages.fcitx5-qt
      kdePackages.fcitx5-configtool
    ];
  };

  # Enable the KDE Plasma Desktop Environment.
  services.displayManager.sddm.enable = true;
  services.desktopManager.plasma6.enable = true;

  hardware.i2c.enable = true;

  # DDC/CI for monitor control
  services.udev.extraRules = ''
  KERNEL=="i2c-[0-9]*", GROUP="ddc", MODE="0660", PROGRAM="${pkgs.ddcutil}/bin/ddcutil --bus=%n getvcp 0x10"
  '';
  users.groups.ddc = { };

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

  # Enable CUPS to print documents.
  services.printing.enable = true;

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

  # Define a user account. Don't forget to set a password with ‘passwd’.
  users.users.zh = {
    isNormalUser = true;
    description = "zh";
    extraGroups = [
      "networkmanager"
      "wheel"
      "docker"
      "i2c"
      "ddc"
      "input"
      "uinput"
    ];
    shell = pkgs.zsh;
  };

  # Install clash-verge.
  programs.clash-verge = {
    enable = true;
    package = pkgs.clash-verge-rev;
    autoStart = false;
    tunMode = true;
    serviceMode = true;
  };

  # Install zsh.
  programs.zsh.enable = true;
  
  # Enable nix ld.
  programs.nix-ld.enable = true;

  # Install Steam
  programs.steam = {
    enable = true;
    remotePlay.openFirewall = true; # Open ports in the firewall for Steam Remote Play
    dedicatedServer.openFirewall = true; # Open ports in the firewall for Source Dedicated Server
    localNetworkGameTransfers.openFirewall = true; # Open ports in the firewall for Steam Local Network Game Transfers
  };

  # Enable Flatpak support.
  services.flatpak.enable = true;
  systemd.services.flatpak-repo = {
    wantedBy = ["multi-user.target"];
    path = [pkgs.flatpak];
    script = ''
      flatpak remote-add --if-not-exists flathub https://dl.flathub.org/repo/flathub.flatpakrepo
    '';
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
    libdbusmenu # https://github.com/microsoft/vscode/issues/34510
    kdePackages.sddm-kcm
    kdePackages.ksystemlog
    kdePackages.xdg-desktop-portal-kde
    xdg-desktop-portal-gtk
  ];

  environment.variables.EDITOR = "neovim";

  environment.sessionVariables.NIXOS_OZONE_WL = "1";

  fonts.packages = with pkgs; [
    noto-fonts
    noto-fonts-cjk-sans
    noto-fonts-emoji
    noto-fonts-color-emoji
    liberation_ttf
    nerd-fonts.jetbrains-mono
    sarasa-gothic
    corefonts # Microsoft Core Fonts
    vista-fonts # Vista Fonts
  ];

  fonts.fontconfig.localConf = ''
    <match target="font">
      <test name="family" qual="first">
        <string>Noto Color Emoji</string>
      </test>
      <edit name="antialias" mode="assign">
        <bool>false</bool>
      </edit>
    </match>
  '';

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
  };

  # This value determines the NixOS release from which the default
  # settings for stateful data, like file locations and database versions
  # on your system were taken. It‘s perfectly fine and recommended to leave
  # this value at the release version of the first install of this system.
  # Before changing this value read the documentation for this option
  # (e.g. man configuration.nix or on https://nixos.org/nixos/options.html).
  system.stateVersion = "25.05"; # Did you read the comment?
}
