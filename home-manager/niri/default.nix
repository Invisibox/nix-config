{config, ...}: {
  xdg.configFile."niri/config.kdl".source =
    config.lib.file.mkOutOfStoreSymlink
    "${config.home.homeDirectory}/Documents/nix-config/home-manager/niri/config.kdl";

  services.shikane.enable = true;
}
