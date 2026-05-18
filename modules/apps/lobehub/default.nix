{
  lib,
  config,
  username,
  pkgs,
  ...
}: let
  cfg = config.lobehub;

  pname = "lobehub-desktop";
  version = "2.2.0";

  deps = with pkgs; [
    alsa-lib
    at-spi2-atk
    at-spi2-core
    atk
    cairo
    cups
    dbus
    expat
    fontconfig
    freetype
    gdk-pixbuf
    glib
    gtk3
    libappindicator-gtk3
    libdrm
    libGL
    libgbm
    libnotify
    libsecret
    libuuid
    libx11
    libxcb
    libxcomposite
    libxdamage
    libxext
    libxfixes
    libxi
    libxkbcommon
    libxrandr
    libxrender
    libxscrnsaver
    libxtst
    nspr
    nss
    pango
    udev
    vulkan-loader
    wayland
    zlib
  ];

  rpath = lib.makeLibraryPath deps + ":" + lib.makeSearchPathOutput "lib" "lib64" deps;

  xdgUtilsShim = pkgs.symlinkJoin {
    name = "lobehub-xdg-utils";
    paths = [
      (pkgs.writeShellScriptBin "xdg-mime" ''
        if [[ "$1" == "default" && " $* " == *" x-scheme-handler/lobehub "* ]]; then
          exit 0
        fi

        if [[ "$1" == "query" && "$2" == "default" && "$3" == "x-scheme-handler/lobehub" ]]; then
          echo "lobehub-desktop.desktop"
          exit 0
        fi

        exec ${pkgs.xdg-utils}/bin/xdg-mime "$@"
      '')
      (pkgs.writeShellScriptBin "xdg-settings" ''
        if [[ "$1" == "set" && "$2" == "default-url-scheme-handler" && "$3" == "lobehub" ]]; then
          exit 0
        fi

        if [[ "$1" == "get" && "$2" == "default-url-scheme-handler" && "$3" == "lobehub" ]]; then
          echo "lobehub-desktop.desktop"
          exit 0
        fi

        if [[ "$1" == "check" && "$2" == "default-url-scheme-handler" && "$3" == "lobehub" ]]; then
          [[ "$4" == "lobehub-desktop.desktop" ]]
          exit $?
        fi

        exec ${pkgs.xdg-utils}/bin/xdg-settings "$@"
      '')
    ];
  };

  binpath = lib.makeBinPath [
    xdgUtilsShim
    pkgs.xdg-utils
  ];

  src = pkgs.fetchurl {
    url = "https://github.com/lobehub/lobehub/releases/download/v${version}/lobehub-desktop_${version}_amd64.deb";
    hash = "sha256-D3Nv4OJvQ9WxdVKZNFFEjnwRwDPY8OVkR356GR9VnX4=";
  };

  lobehubPackage = pkgs.stdenv.mkDerivation {
    inherit pname version src;

    nativeBuildInputs = [
      pkgs.autoPatchelfHook
      pkgs.dpkg
      pkgs.imagemagick
      (pkgs.buildPackages.wrapGAppsHook3.override {makeWrapper = pkgs.buildPackages.makeShellWrapper;})
    ];

    buildInputs =
      deps
      ++ (with pkgs; [
        adwaita-icon-theme
        gsettings-desktop-schemas
      ]);

    dontConfigure = true;
    dontBuild = true;

    unpackPhase = ''
      runHook preUnpack
      dpkg-deb --fsys-tarfile "$src" | tar --extract --no-same-owner --no-same-permissions
      runHook postUnpack
    '';

    installPhase = ''
      runHook preInstall

      mkdir -p "$out/bin" "$out/opt" "$out/share"
      cp -R opt "$out/"
      cp -R usr/share/* "$out/share/"

      icon_src="$out/share/icons/hicolor/514x514/apps/lobehub-desktop.png"
      for icon_size in 128 256 512; do
        install -d "$out/share/icons/hicolor/''${icon_size}x''${icon_size}/apps"
        magick "$icon_src" -resize "''${icon_size}x''${icon_size}" \
          "$out/share/icons/hicolor/''${icon_size}x''${icon_size}/apps/lobehub-desktop.png"
      done

      makeWrapper "$out/opt/LobeHub/lobehub-desktop" "$out/bin/lobehub-desktop" \
        --unset ELECTRON_RUN_AS_NODE

      substituteInPlace "$out/share/applications/lobehub-desktop.desktop" \
        --replace-fail "/opt/LobeHub/lobehub-desktop" "lobehub-desktop"

      runHook postInstall
    '';

    preFixup = ''
      gappsWrapperArgs+=(
        --prefix LD_LIBRARY_PATH : ${rpath}:$out/opt/LobeHub
        --prefix PATH : ${binpath}
      )
    '';

    meta = with lib; {
      description = "LobeHub Desktop";
      homepage = "https://github.com/lobehub/lobehub";
      license = licenses.mit;
      platforms = ["x86_64-linux"];
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

    home-manager.users.${username}.xdg.mimeApps = {
      enable = true;
      defaultApplications."x-scheme-handler/lobehub" = ["lobehub-desktop.desktop"];
    };
  };
}
