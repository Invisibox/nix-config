{
  pkgs,
  config,
  ...
}: {
  home.sessionVariables = {
    EDITOR = "neovim";
    XCURSOR_THEME = "Bibata-Modern-Ice";
    XCURSOR_SIZE = "20";
    XCURSOR_PATH = "${pkgs.bibata-cursors}/share/icons:/run/current-system/sw/share/icons";
    QT_QPA_PLATFORMTHEME_QT6 = "qt6ct";
  };

  systemd.user.sessionVariables = {
    QT_QPA_PLATFORMTHEME_QT6 = "qt6ct";
  };

  home.pointerCursor = {
    gtk.enable = true;
    x11.enable = true;
    name = "Bibata-Modern-Ice";
    package = pkgs.bibata-cursors;
    size = 20;
  };

  gtk = {
    enable = true;
    iconTheme = {
      package = pkgs.papirus-icon-theme;
      name = "Papirus";
    };
    gtk4.theme = config.gtk.theme;
  };

  qt = {
    enable = true;
    platformTheme.name = "qtct";
  };
}
