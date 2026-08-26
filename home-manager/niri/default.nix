{config, ...}: {
  xdg.configFile."niri/config.kdl".source =
    config.lib.file.mkOutOfStoreSymlink
    "${config.home.homeDirectory}/Documents/nix-config/home-manager/niri/config.kdl";

  xdg.configFile."shikane/config.toml".source = ./shikane/config.toml;

  services.shikane.enable = true;
}
