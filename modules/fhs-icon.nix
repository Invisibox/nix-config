{pkgs, ...}: {
  system.fsPackages = [pkgs.bindfs];
  fileSystems = let
    mkRoSymBind = path: {
      device = path;
      fsType = "fuse.bindfs";
      options = ["ro" "resolve-symlinks" "x-gvfs-hide"];
    };
    aggregated = pkgs.buildEnv {
      name = "system-fonts-and-icons";
      paths = with pkgs; [
        bibata-cursors

        noto-fonts
        noto-fonts-cjk-sans
        noto-fonts-cjk-serif
        noto-fonts-emoji
        noto-fonts-color-emoji
        liberation_ttf
        nerd-fonts.jetbrains-mono
        sarasa-gothic
        lxgw-wenkai
        windows-fonts
        nerd-fonts.jetbrains-mono
      ];
      pathsToLink = ["/share/fonts" "/share/icons"];
    };
  in {
    # Create an FHS mount to support flatpak host icons/fonts
    "/usr/share/icons" = mkRoSymBind "${aggregated}/share/icons";
    "/usr/share/fonts" = mkRoSymBind "${aggregated}/share/fonts";
  };
}
