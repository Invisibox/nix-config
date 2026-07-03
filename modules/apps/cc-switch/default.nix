{
  lib,
  config,
  username,
  pkgs,
  ...
}: let
  cfg = config.cc-switch;

  pname = "cc-switch";
  version = "3.16.5";

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
    glib-networking
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
    openssl
    pango
    pkgs.stdenv.cc.cc.lib
    udev
    vulkan-loader
    wayland
    xz
    zlib
    libsoup_3
    webkitgtk_4_1
  ];

  rpath = lib.makeLibraryPath deps + ":" + lib.makeSearchPathOutput "lib" "lib64" deps;
  binpath = lib.makeBinPath [pkgs.xdg-utils];

  src = pkgs.fetchurl {
    url = "https://github.com/farion1231/cc-switch/releases/download/v${version}/CC-Switch-v${version}-Linux-x86_64.deb";
    hash = "sha256-uhyTXVbz0b9GCrphRAXLYUlyK3hcjqwmZJD76En/kJY=";
  };

  ccSwitchPackage = pkgs.stdenv.mkDerivation {
    inherit pname version src;

    nativeBuildInputs = [
      pkgs.autoPatchelfHook
      pkgs.dpkg
      pkgs.imagemagick
      pkgs.wrapGAppsHook3
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
      dpkg-deb -x "$src" .
      runHook postUnpack
    '';

    installPhase = ''
      runHook preInstall

      mkdir -p "$out/bin" "$out/share"
      cp -R usr/* "$out/"

      if [[ -f "$out/share/applications/CC Switch.desktop" ]]; then
        mv "$out/share/applications/CC Switch.desktop" "$out/share/applications/cc-switch.desktop"
      fi

      icon_src=
      for candidate in 256x256@2 128x128 32x32; do
        candidate_path="$out/share/icons/hicolor/''${candidate}/apps/cc-switch.png"
        if [[ -e "$candidate_path" ]]; then
          icon_src="$candidate_path"
          break
        fi
      done

      if [[ -z "$icon_src" ]]; then
        echo "missing cc-switch icon asset" >&2
        exit 1
      fi

      for icon_size in 128 256 512; do
        install -d "$out/share/icons/hicolor/''${icon_size}x''${icon_size}/apps"
        magick "$icon_src" -resize "''${icon_size}x''${icon_size}" \
          "$out/share/icons/hicolor/''${icon_size}x''${icon_size}/apps/cc-switch.png"
      done

      chmod +x "$out/bin/cc-switch"

      runHook postInstall
    '';

    preFixup = ''
      gappsWrapperArgs+=(
        --prefix LD_LIBRARY_PATH : ${rpath}
        --prefix PATH : ${binpath}
      )
    '';

    meta = with lib; {
      description = "All-in-One Assistant for Claude Code, Codex & Gemini CLI";
      homepage = "https://github.com/farion1231/cc-switch";
      license = licenses.mit;
      mainProgram = "cc-switch";
      platforms = ["x86_64-linux"];
      sourceProvenance = with sourceTypes; [binaryNativeCode];
    };
  };
in {
  options.cc-switch = {
    enable = lib.mkEnableOption "Enable CC Switch";

    package = lib.mkOption {
      type = lib.types.package;
      default = ccSwitchPackage;
      description = "The CC Switch package installed for the user.";
    };
  };

  config = lib.mkIf cfg.enable {
    environment.systemPackages = [cfg.package];

    home-manager.users.${username}.xdg.mimeApps = {
      enable = true;
      defaultApplications."x-scheme-handler/ccswitch" = ["cc-switch.desktop"];
    };
  };
}
