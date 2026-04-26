{
  lib,
  config,
  username,
  pkgs,
  ...
}: let
  cfg = config.steam;
  gamescopeEnabled = config.gamescope.enable;
  gamescopePackage = config.programs.gamescope.package;
  steamGameWrapper = pkgs.callPackage ./game-wrapper.nix {
    gamescope = gamescopePackage;
  };
  steamRuntimeEnv = {
    PIPEWIRE_NODE = "Game";
    PULSE_SINK = "Game";
    PROTON_ENABLE_HDR = "1";
    PROTON_ENABLE_WAYLAND = "1";
    PROTON_FSR4_RDNA3_UPGRADE = "1";
    PROTON_USE_NTSYNC = "1";
    PROTON_USE_WOW64 = "1";
  };
in {
  options.steam = {
    enable = lib.mkEnableOption "Enable Steam in NixOS";
    enableNative = lib.mkOption {
      type = lib.types.bool;
      default = true;
    };
    enableSteamBeta = lib.mkOption {
      type = lib.types.bool;
      default = true;
    };
    # https://reddit.com/r/linux_gaming/comments/16e1l4h/slow_steam_downloads_try_this/
    fixDownloadSpeed = lib.mkOption {
      type = lib.types.bool;
      default = false;
    };
  };
  config = lib.mkIf cfg.enable {
    programs.steam = {
      enable = cfg.enableNative;
      package = pkgs.steam.override {
        extraEnv = steamRuntimeEnv;
        # https://github.com/NixOS/nixpkgs/issues/279893#issuecomment-2425213386
        extraProfile = ''
          unset TZ
        '';
        privateTmp = false; # https://github.com/NixOS/nixpkgs/issues/381923
      };
      extraCompatPackages = with pkgs; [
        proton-em
        proton-ge
      ];
      extraPackages = [
        pkgs.gamemode
        gamescopePackage
        pkgs.mangohud
        pkgs.obs-studio-plugins.obs-vkcapture
      ];
      extest.enable = true;
      gamescopeSession = lib.mkIf gamescopeEnabled {
        enable = true;
        args = [
          "--adaptive-sync"
          "--mangoapp"
        ];
      };
      localNetworkGameTransfers.openFirewall = true;
      protontricks.enable = true;
      remotePlay.openFirewall = true;
    };
    programs.gamemode = {
      enable = true;
      settings.general.renice = 10;
    };
    users.users.${username}.extraGroups = ["gamemode"];
    home-manager.users.${username} = {
      pkgs,
      config,
      ...
    }: {
      home = {
        file = {
          steam-beta = {
            enable = cfg.enableSteamBeta;
            text = "publicbeta";
            target = "${config.xdg.dataHome}/Steam/package/beta";
          };
          steam-config-default = {
            enable = true;
            source = lib.getExe steamGameWrapper;
            target = "${config.xdg.dataHome}/steam-config-nix/users/shared/app-wrappers/default";
          };
          steam-slow-fix = {
            enable = cfg.fixDownloadSpeed;
            text = ''
              @nClientDownloadEnableHTTP2PlatformLinux 0
              @fDownloadRateImprovementToAddAnotherConnection 1.0
            '';
            target = "${config.xdg.dataHome}/Steam/steam_dev.cfg";
          };
        };
        packages = with pkgs; [
          steamGameWrapper
          steamcmd
        ];
      };
      xdg.desktopEntries.steam-gamescope = lib.mkIf gamescopeEnabled {
        name = "Steam (Gamescope)";
        genericName = "Steam running inside Gamescope";
        exec = "steam-gamescope";
        icon = "steam";
        terminal = false;
        categories = ["Game"];
      };
      # https://github.com/different-name/steam-config-nix
      programs.steam.config = import ./steam-config.nix {inherit lib pkgs config steamGameWrapper;};
    };
  };
}
