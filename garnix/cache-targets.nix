{
  config,
  inputs,
  lib,
  pkgs,
  system,
}: let
  findPackage = packages: name:
    lib.findFirst
    (pkg: lib.getName pkg == name)
    (throw "Package '${name}' was not found in ASUS configuration")
    packages;

  hmPackage = findPackage config.home-manager.users.zh.home.packages;
  systemPackage = findPackage config.environment.systemPackages;
in {
  dae = inputs.daeuniverse.packages.${system}.dae;
  daed = config.daed.package;
  daed-assets = pkgs.symlinkJoin {
    name = "daed-assets";
    paths = config.daed.assets;
  };

  dms-shell = hmPackage "dms-shell";
  dms-quickshell = hmPackage "quickshell-wrapped";
  niri = config.programs.niri.package;

  gamescope = config.programs.gamescope.package;
  heroic = hmPackage "heroic";
  lobehub-desktop = config.lobehub.package;
  mpv = config.home-manager.users.zh.programs.mpv.package;
  nautilus-env = hmPackage "nautilus-env";
  obs-studio = config.home-manager.users.zh.programs.obs-studio.finalPackage;
  obs-cmd = hmPackage "obs-cmd";

  proton-em = pkgs.proton-em;
  proton-ge = pkgs.proton-ge;
  steam = config.programs.steam.package;
  steam-game-wrapper = hmPackage "steam-game-wrapper";
  steam-gamescope = systemPackage "steam-gamescope";
  steam-run = systemPackage "steam-run";

  fluent-reader = hmPackage "fluent-reader";
  qq = hmPackage "qq-sandboxed";
  tor-browser = hmPackage "tor-browser";
  vial = hmPackage "Vial";
  wechat = config.im.wechatPackage;
  wemeet = config.wemeet.package;
  wemeet-base = config.wemeet.basePackage;
  windows-fonts = inputs.chinese-fonts-overlay.packages.${system}.windows-fonts;
  wps = hmPackage "wpsoffice-cn";
  zen-browser = hmPackage "zen-beta";

  spiced-spotify = config.home-manager.users.zh.programs.spicetify.spicedSpotify;
  waydroid = config.waydroid.package;
  waydroid-init-default = systemPackage "waydroid-init-default";
}
