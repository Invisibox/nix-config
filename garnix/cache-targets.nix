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
  brave-origin = config.brave-origin.package;
  dae = inputs.daeuniverse.packages.${system}.dae;
  daed = config.daed.package;
  daed-assets = pkgs.symlinkJoin {
    name = "daed-assets";
    paths = config.daed.assets;
  };

  dms-shell = hmPackage "dms-shell";
  dms-quickshell = hmPackage "quickshell-wrapped";

  gamescope = systemPackage "gamescope";
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
  steam-run = systemPackage "steam-run";

  fluent-reader = hmPackage "fluent-reader";
  file-roller = hmPackage "file-roller";
  fcitx5-rime-with-data = pkgs.fcitx5-rime.override {
    rimeDataPkgs = [
      pkgs.rime-data
      pkgs.rime-wanxiang
    ];
  };
  fcitx5-with-addons = systemPackage "fcitx5-with-addons";
  qq = hmPackage "qq-sandboxed";
  qimgv = hmPackage "qimgv";
  neovim = systemPackage "neovim";
  nh = systemPackage "nh";
  nodejs = hmPackage "nodejs";
  postgresql-and-plugins = systemPackage "postgresql-and-plugins";
  protontricks = systemPackage "protontricks";
  rime-wanxiang = pkgs.rime-wanxiang;
  rime-wanxiang-lts-gram = pkgs.rime-wanxiang-lts-gram;
  texlive-combined-full = hmPackage "texlive-combined-full";
  thunderbird = hmPackage "thunderbird";
  tor-browser = hmPackage "tor-browser";
  vial = hmPackage "Vial";
  wechat = config.im.wechatPackage;
  wemeet = config.wemeet.package;
  wemeet-base = config.wemeet.basePackage;
  windows-fonts = inputs.chinese-fonts-overlay.packages.${system}.windows-fonts;
  winbox = hmPackage "winbox";
  wps = hmPackage "wpsoffice-cn";
  zen-browser = hmPackage "zen-beta";

  spiced-spotify = config.home-manager.users.zh.programs.spicetify.spicedSpotify;
  waydroid = config.waydroid.package;
  waydroid-init-default = systemPackage "waydroid-init-default";
}
