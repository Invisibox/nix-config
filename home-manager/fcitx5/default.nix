{
  flake.modules.homeManager.desktop = {
    config,
    lib,
    pkgs,
    ...
  }: {
    xdg.dataFile = {
      "fcitx5/themes/OriLight".source = ./ori/OriLight;
      "fcitx5/themes/OriDark".source = ./ori/OriDark;
    };

    # Keep classicui.conf writable by Fcitx and preserve font/layout preferences.
    home.activation.selectOriTheme = lib.hm.dag.entryAfter ["linkGeneration"] ''
      classicui=${lib.escapeShellArg "${config.xdg.configHome}/fcitx5/conf/classicui.conf"}
      run mkdir -p "$(dirname "$classicui")"
      if [ -f "$classicui" ] && [ ! -e "$classicui.before-ori" ]; then
        run cp -p "$classicui" "$classicui.before-ori"
      fi
      run ${pkgs.crudini}/bin/crudini --set "$classicui" "" Theme OriLight
      run ${pkgs.crudini}/bin/crudini --set "$classicui" "" DarkTheme OriDark
      run ${pkgs.crudini}/bin/crudini --set "$classicui" "" UseDarkTheme True
    '';
  };
}
