{
  lib,
  config,
  username,
  pkgs,
  ...
}: let
  cfg = config.oxide-term;

  pname = "oxideterm";
  version = "1.6.2";

  src = pkgs.fetchurl {
    url = "https://github.com/AnalyseDeCircuit/oxideterm/releases/download/v${version}/OxideTerm_${version}_linux_x64.deb";
    hash = "sha256-MKgnVAqLJ5vK6StQWsqCFY+HFNsBOx+ytK0vcPmviBE=";
  };

  oxideTermPackage = pkgs.stdenv.mkDerivation {
    inherit pname version src;

    nativeBuildInputs = [
      pkgs.autoPatchelfHook
      pkgs.dpkg
      pkgs.wrapGAppsHook3
    ];

    buildInputs = with pkgs; [
      cairo
      dbus
      gdk-pixbuf
      glib
      glib-networking
      gtk3
      libsoup_3
      webkitgtk_4_1
    ];

    dontConfigure = true;
    dontBuild = true;

    unpackPhase = ''
      runHook preUnpack
      dpkg-deb -x "$src" .
      runHook postUnpack
    '';

    installPhase = ''
      runHook preInstall

      mkdir -p "$out"
      cp -R usr/* "$out/"
      chmod +x "$out/bin/oxideterm"
      chmod +x "$out/lib/OxideTerm/cli-bin/oxt"
      chmod +x "$out/lib/OxideTerm/agents/"*

      runHook postInstall
    '';

    postFixup = ''
      ln -s "$out/lib/OxideTerm/cli-bin/oxt" "$out/bin/oxt"
    '';

    preFixup = ''
      gappsWrapperArgs+=(
        --set-default OXIDETERM_LINUX_WEBVIEW_PROFILE safe
        --set-default WEBKIT_DISABLE_DMABUF_RENDERER 1
        --set-default WEBKIT_DISABLE_COMPOSITING_MODE 1
      )
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
    home-manager.users.${username} = {
      home = {
        file.".local/bin/oxt".source = "${cfg.package}/lib/OxideTerm/cli-bin/oxt";

        packages = [
          cfg.package
        ];
      };
    };
  };
}
