{
  lib,
  config,
  pkgs,
  inputs,
  ...
}: let
  cfg = config.local.apps.onlyoffice;
  localUserName = config.local.user.name;
in {
  options.local.apps.onlyoffice = {
    enable = lib.mkEnableOption "Enable OnlyOffice Desktop Editors";

    package = lib.mkOption {
      type = lib.types.package;
      default = pkgs.onlyoffice-desktopeditors;
      description = "OnlyOffice package installed for the user through Home Manager.";
    };

    windowsFontsPackage = lib.mkOption {
      type = with lib.types; nullOr package;
      default = null;
      defaultText = lib.literalExpression ''
        null
        # fallback when local.apps.onlyoffice.enable = true:
        # inputs.chinese-fonts-overlay.packages.${pkgs.stdenv.hostPlatform.system}.windows-fonts
      '';
      description = ''
        Windows font package exposed to OnlyOffice via its private Fontconfig.
        If null, fallback to windows-fonts from chinese-fonts-overlay when OnlyOffice is enabled.
      '';
    };
  };

  config = lib.mkIf cfg.enable (let
    # Keep chinese-fonts-overlay lazy so it is not fetched/evaluated unless OnlyOffice is enabled.
    system = pkgs.stdenv.hostPlatform.system;
    defaultWindowsFontsPackage = inputs.chinese-fonts-overlay.packages.${system}.windows-fonts;
    windowsFontsPackage =
      if cfg.windowsFontsPackage == null
      then defaultWindowsFontsPackage
      else cfg.windowsFontsPackage;

    onlyofficeFontsConf = pkgs.writeText "onlyoffice-fonts.conf" ''
      <?xml version="1.0"?>
      <!DOCTYPE fontconfig SYSTEM "urn:fontconfig:fonts.dtd">
      <fontconfig>
        <reset-dirs />
        <dir>${windowsFontsPackage}/share/fonts</dir>
      </fontconfig>
    '';

    # OnlyOffice scans /usr/share/fonts directly in addition to using Fontconfig.
    # Mount the complete Windows font package into its FHS environment as well.
    packageWithFonts = cfg.package.overrideAttrs (old: {
      extraBwrapArgs =
        (old.extraBwrapArgs or [])
        ++ [
          "--ro-bind"
          "${windowsFontsPackage}/share/fonts"
          "/usr/share/fonts"
        ];
    });

    wrappedOnlyOfficePackage = pkgs.symlinkJoin {
      name = "${packageWithFonts.name or "onlyoffice-desktopeditors"}-with-fonts";
      paths = [packageWithFonts];
      nativeBuildInputs = [pkgs.makeWrapper];
      postBuild = ''
        rm -rf "$out/bin"
        mkdir -p "$out/bin"

        for bin in "${packageWithFonts}/bin"/*; do
          bin_name="$(basename "$bin")"
          if [ -x "$bin" ] && [ ! -d "$bin" ]; then
            makeWrapper "$bin" "$out/bin/$bin_name" \
              --set FONTCONFIG_FILE "${onlyofficeFontsConf}" \
              --run '
                onlyoffice_fonts_cache="$HOME/.local/share/onlyoffice/desktopeditors/data/fonts"
                onlyoffice_fonts_marker="$onlyoffice_fonts_cache/.nix-windows-fonts"
                if [ ! -f "$onlyoffice_fonts_marker" ] || [ "$(cat "$onlyoffice_fonts_marker" 2>/dev/null)" != "${windowsFontsPackage}" ]; then
                  rm -f "$onlyoffice_fonts_cache"/AllFonts.js* \
                    "$onlyoffice_fonts_cache"/font_selection.bin \
                    "$onlyoffice_fonts_cache"/fonts.log \
                    "$onlyoffice_fonts_cache"/fonts_thumbnail*
                  mkdir -p "$onlyoffice_fonts_cache"
                  printf "%s" "${windowsFontsPackage}" > "$onlyoffice_fonts_marker"
                fi'
          else
            ln -s "$bin" "$out/bin/$bin_name"
          fi
        done

        rm -rf "$out/share/applications"
        mkdir -p "$out/share"
        cp -r "${packageWithFonts}/share/applications" "$out/share/applications"
        substituteInPlace "$out/share/applications/onlyoffice-desktopeditors.desktop" \
          --replace-quiet "${packageWithFonts}/bin/onlyoffice-desktopeditors" \
          "$out/bin/onlyoffice-desktopeditors" \
          --replace-quiet "/usr/bin/onlyoffice-desktopeditors" \
          "$out/bin/onlyoffice-desktopeditors"
      '';
    };
  in {
    home-manager.users.${localUserName}.home.packages = [
      wrappedOnlyOfficePackage
    ];
  });
}
