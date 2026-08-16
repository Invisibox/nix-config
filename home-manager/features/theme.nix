{
  pkgs,
  config,
  ...
}: {
  home.sessionVariables = {
    EDITOR = "neovim";
    XCURSOR_THEME = "Bibata-Modern-Ice";
    XCURSOR_SIZE = "22";
    QT_QPA_PLATFORMTHEME_QT6 = "qt6ct";
  };

  systemd.user.sessionVariables = {
    QT_QPA_PLATFORMTHEME_QT6 = "qt6ct";
  };

  home.packages = with pkgs; [
    adw-gtk3
    gsettings-desktop-schemas
  ];

  home.pointerCursor = {
    enable = true;
    gtk.enable = true;
    x11.enable = true;
    name = "Bibata-Modern-Ice";
    package = pkgs.bibata-cursors;
    size = 22;
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
