{
  lib,
  pkgs,
}: let
  pname = "paseo";
  version = "0.3.0";

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
    libdrm
    libgbm
    libGL
    libx11
    libxcb
    libxcomposite
    libxcursor
    libxdamage
    libxext
    libxfixes
    libxi
    libxkbcommon
    libxrandr
    mesa
    nspr
    nss
    pango
    pipewire
    systemd
    udev
    vulkan-loader
    wayland
    xdg-utils
    zlib
  ];

  rpath = lib.makeLibraryPath deps;
  binpath = lib.makeBinPath deps;
in
  pkgs.stdenv.mkDerivation {
    inherit pname version;

    src = pkgs.fetchurl {
      url = "https://github.com/getpaseo/paseo/releases/download/v${version}/Paseo-${version}-amd64.deb";
      hash = "sha256-J6tuFZermvTe7E2rqjVRolepE12RlBNjbJroj6nZCHU=";
    };

    dontConfigure = true;
    dontBuild = true;
    dontPatchELF = true;
    doInstallCheck = true;

    nativeBuildInputs = [
      pkgs.autoPatchelfHook
      pkgs.dpkg
      (pkgs.buildPackages.wrapGAppsHook3.override {makeWrapper = pkgs.buildPackages.makeShellWrapper;})
    ];

    buildInputs = deps ++ (with pkgs; [
      adwaita-icon-theme
      gsettings-desktop-schemas
      gtk3
    ]);

    unpackPhase = ''
      runHook preUnpack
      dpkg-deb --fsys-tarfile "$src" | tar --extract --no-same-owner --no-same-permissions
      runHook postUnpack
    '';

    installPhase = ''
      runHook preInstall

      mkdir -p "$out/bin"
      cp -R opt "$out/"
      cp -R usr/share "$out/share"

      app_dir="$out/opt/Paseo"
      app_binary="$app_dir/Paseo"
      cli_binary="$app_dir/resources/bin/paseo"

      chmod +x "$app_binary" "$cli_binary"
      ln -s "$app_binary" "$out/bin/paseo"
      ln -s "$cli_binary" "$out/bin/paseo-cli"

      for desktop_file in "$out/share/applications/"*.desktop; do
        substituteInPlace "$desktop_file" \
          --replace-fail "/opt/Paseo/Paseo" "$out/bin/paseo"
      done

      runHook postInstall
    '';

    preFixup = ''
      gappsWrapperArgs+=(
        --prefix LD_LIBRARY_PATH : ${rpath}
        --prefix PATH : ${binpath}
      )
    '';

    installCheckPhase = ''
      "$out/bin/paseo-cli" --version
    '';

    meta = {
      description = "Desktop and mobile client for orchestrating coding agents";
      homepage = "https://paseo.sh";
      license = lib.licenses.agpl3Only;
      mainProgram = "paseo";
      platforms = ["x86_64-linux"];
      sourceProvenance = with lib.sourceTypes; [binaryNativeCode];
    };
  }
