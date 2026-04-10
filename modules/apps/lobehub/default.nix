{
  lib,
  config,
  pkgs,
  ...
}: let
  cfg = config.lobehub;

  pname = "lobehub-desktop";
  version = "2.1.48";

  src = pkgs.fetchurl {
    url = "https://github.com/lobehub/lobehub/releases/download/v${version}/LobeHub-${version}.AppImage";
    hash = "sha256-xjfaIDRdORsabaDWeIaXsVfkvmIwPgA4Lw3WR99IbAk=";
  };

  appimageContents = pkgs.appimageTools.extractType2 {
    inherit pname version src;
  };

  lobehubPackage = pkgs.appimageTools.wrapType2 {
    inherit pname version src;

    extraInstallCommands = ''
      install -Dm444 ${appimageContents}/lobehub-desktop.desktop \
        $out/share/applications/lobehub-desktop.desktop

      substituteInPlace $out/share/applications/lobehub-desktop.desktop \
        --replace-fail 'Exec=AppRun --no-sandbox %U' 'Exec=lobehub-desktop --no-sandbox %U'

      install -Dm444 ${appimageContents}/lobehub-desktop.png \
        $out/share/icons/hicolor/512x512/apps/lobehub-desktop.png
    '';

    meta = with lib; {
      description = "LobeHub Desktop";
      homepage = "https://github.com/lobehub/lobehub";
      license = licenses.mit;
      platforms = platforms.linux;
      sourceProvenance = with sourceTypes; [binaryNativeCode];
      mainProgram = "lobehub-desktop";
    };
  };
in {
  options.lobehub = {
    enable = lib.mkEnableOption "Enable LobeHub Desktop";

    package = lib.mkOption {
      type = lib.types.package;
      default = lobehubPackage;
      description = "The LobeHub Desktop package to use.";
    };
  };

  config = lib.mkIf cfg.enable {
    environment.systemPackages = [cfg.package];
  };
}
