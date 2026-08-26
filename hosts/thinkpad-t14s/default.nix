{
  pkgs,
  lib,
  config,
  inputs,
  ...
}: {
  imports = [
    ./disko.nix
    ../../hardware-configuration.nix
    ../../font.nix
    ../../nix.nix
    ../../printing.nix
    ../../modules
    ../../profiles/desktop.nix
    ../../profiles/gaming.nix
    ../../profiles/apps.nix
    ../../profiles/dev.nix
    ../../profiles/services.nix
  ];

  boot.loader = {
    systemd-boot.enable = lib.mkForce false;
    efi = {
      canTouchEfiVariables = true;
      efiSysMountPoint = "/boot";
    };
  };

  boot.lanzaboote = {
    enable = true;
    pkiBundle = "/var/lib/sbctl";
    configurationLimit = 10;
    autoGenerateKeys.enable = true;
  };

  environment.systemPackages = [pkgs.sbctl];

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

  nixpkgs.overlays = [inputs.nix-cachyos-kernel.overlays.pinned];

  # Core Ultra 5 135U supports x86-64-v3.
  boot.kernelPackages = pkgs.cachyosKernels.linuxPackages-cachyos-latest-x86_64-v3;

  networking.hostName = "thinkpad-t14s";
  networking.networkmanager.enable = true;

  hardware.enableRedistributableFirmware = true;
  hardware.graphics = {
    enable = true;
    enable32Bit = true;
  };
  hardware.intelgpu.vaapiDriver = "intel-media-driver";
  hardware.i2c.enable = true;
  hardware.bluetooth = {
    enable = true;
    powerOnBoot = true;
  };

  services.fwupd.enable = true;
  services.fprintd.enable = true;
  services.thermald.enable = true;
  services.hardware.bolt.enable = true;

  zramSwap = {
    enable = true;
    algorithm = "zstd";
    memoryPercent = 25;
    priority = 100;
  };

  services.accounts-daemon.enable = true;

  time.timeZone = "Asia/Shanghai";

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
      (fcitx5-rime.override {
        rimeDataPkgs = [rime-data];
      })
      fcitx5-gtk
      fcitx5-mellow-themes
      qt6Packages.fcitx5-configtool
    ];
  };
  programs.gdk-pixbuf.modulePackages = with pkgs; [librsvg];

  services.udev.extraRules = ''
    KERNEL=="i2c-[0-9]-*", SUBSYSTEM=="i2c-dev", GROUP="i2c", MODE="0660"
  '';

  services.xserver.xkb = {
    layout = "us";
    variant = "";
  };

  services.pulseaudio.enable = false;
  security.rtkit.enable = true;
  services.pipewire = {
    enable = true;
    alsa.enable = true;
    alsa.support32Bit = true;
    pulse.enable = true;
  };

  environment.sessionVariables = {
    XDG_CACHE_HOME = "$HOME/.cache";
    XDG_CONFIG_HOME = "$HOME/.config";
    XDG_DATA_HOME = "$HOME/.local/share";
    XDG_STATE_HOME = "$HOME/.local/state";
    PATH = ["$HOME/.local/bin"];
    ZDOTDIR = "$XDG_CONFIG_HOME/zsh";
    SYSTEMD_PAGERSECURE = "false";
  };
  environment.variables.EDITOR = "neovim";

  users.users.zh = {
    isNormalUser = true;
    description = "zh";
    extraGroups = [
      "networkmanager"
      "wheel"
      "i2c"
      "input"
      "uinput"
    ];
    shell = pkgs.zsh;
  };
  users.groups.netdev = {};
  programs.zsh.enable = true;
  users.defaultUserShell = pkgs.zsh;
  programs.nano.enable = false;

  services.kanata = {
    enable = true;
    package = pkgs.kanata;
    keyboards.internalKeyboard = {
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

  networking.firewall.enable = true;

  system.stateVersion = "26.05";
}
