{
  lib,
  config,
  username,
  pkgs,
  ...
}: let
  cfg = config.oxide-term;

  pname = "oxideterm";
  version = "1.4.3";

  src = pkgs.fetchurl {
    url = "https://github.com/AnalyseDeCircuit/oxideterm/releases/download/v${version}/OxideTerm_${version}_linux_x64.AppImage";
    hash = "sha256-3o0Ntez2ETTp6VNRx9PXyMoDBmxpmX3YW298ADNRc78=";
  };

  appimageContents = pkgs.appimageTools.extractType2 {
    inherit pname version src;
  };

  oxideTermPackage = pkgs.appimageTools.wrapType2 {
    inherit pname version src;

    extraInstallCommands = ''
      install -Dm444 ${appimageContents}/usr/share/applications/OxideTerm.desktop \
        $out/share/applications/OxideTerm.desktop

      cp -R ${appimageContents}/usr/share/icons $out/share/
    '';

    meta = {
      description = "Modern SSH terminal client built with Rust and Tauri";
      homepage = "https://github.com/AnalyseDeCircuit/oxideterm";
      license = lib.licenses.gpl3Only;
      mainProgram = "oxideterm";
      platforms = ["x86_64-linux"];
      sourceProvenance = with lib.sourceTypes; [binaryNativeCode];
    };
  };
in {
  options.oxide-term = {
    enable = lib.mkEnableOption "Enable OxideTerm via Home Manager";

    package = lib.mkOption {
      type = lib.types.package;
      default = oxideTermPackage;
      description = "The OxideTerm package installed for the user.";
    };
  };

  config = lib.mkIf cfg.enable {
    home-manager.users.${username}.home.packages = [
      cfg.package
    ];
  };
}
