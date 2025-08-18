{
  config,
  lib,
  ...
}: let
  cursor-theme = "Bibata-Modern-Ice";
in {
  gtk = {
    enable = true;
    cursorTheme = {
      name = lib.mkDefault "${cursor-theme}";
      size = 20;
    };
  };

  home = {
    sessionVariables = {
      GSETTINGS_BACKEND = "keyfile";
      GTK_USE_PORTAL = "1";
      XCURSOR_NAME = "${cursor-theme}";
      XCURSOR_SIZE = "20";
    };
    file.cursor-theme-default = {
      enable = false;
      text = ''
        [Icon Theme]
        Inherits=${cursor-theme}
      '';
      target = "${config.xdg.dataHome}/icons/default/index.theme";
    };
  };

  services = {
    xsettingsd = {
      settings = {
        "Gtk/CursorThemeSize" = 20;
        "Gtk/CursorThemeName" = "${cursor-theme}";
      };
    };
  };
}
