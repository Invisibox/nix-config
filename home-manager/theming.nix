{
  config,
  lib,
  pkgs,
  ...
}: let
  cursor-theme = "Bibata-Modern-Ice";
  bibata-cursor-default-theme = pkgs.runCommandLocal "bibata-cursor-default-theme" { } ''
    mkdir -p $out/share/icons
    # 将链接指向新的光标主题
    ln -s ${pkgs.bibata-cursors}/share/icons/Bibata-Modern-Ice $out/share/icons/default
  '';
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

  home.packages = with pkgs; [
    bibata-cursors
    bibata-cursor-default-theme
  ];

  home.file.".icons/default".source = "${pkgs.bibata-cursors}/share/icons/Bibata-Modern-Ice";

  services = {
    xsettingsd = {
      settings = {
        "Gtk/CursorThemeSize" = 20;
        "Gtk/CursorThemeName" = "${cursor-theme}";
      };
    };
  };
  

}
