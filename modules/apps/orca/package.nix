{
  lib,
  pkgs,
}: let
  pname = "orca";
  version = "1.4.150";

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
  binpath = lib.makeBinPath [pkgs.xdg-utils];
in
  pkgs.stdenv.mkDerivation {
    inherit pname version;

    src = pkgs.fetchurl {
      url = "https://github.com/stablyai/orca/releases/download/v${version}/orca-ide_${version}_amd64.deb";
      hash = "sha256-1ODcwCebA8+kIi4N8jvJqFMXweZHIabwb8Bp3J93L9k=";
    };

    nativeBuildInputs = [
      pkgs.autoPatchelfHook
      pkgs.dpkg
      (pkgs.buildPackages.wrapGAppsHook3.override {makeWrapper = pkgs.buildPackages.makeShellWrapper;})
    ];

    buildInputs = deps ++ (with pkgs; [
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
      cp -R opt/* "$out/opt/"
      if [[ -d usr/share ]]; then
        cp -R usr/share/* "$out/share/"
      fi

      app_dir="$out/opt/Orca"
      chmod +x "$app_dir/orca-ide"

      makeWrapper "$app_dir/orca-ide" "$out/bin/orca" \
        --unset ELECTRON_RUN_AS_NODE

      install -Dm644 -T /dev/stdin "$out/share/applications/orca.desktop" <<'EOF'
      [Desktop Entry]
      Name=Orca
      Comment=Next-gen IDE for parallel agentic development
      Exec=orca %U
      Terminal=false
      Type=Application
      Categories=Development;IDE;
      StartupWMClass=Orca
      EOF

      runHook postInstall
    '';

    preFixup = ''
      addAutoPatchelfSearchPath "$out/opt/Orca"

      gappsWrapperArgs+=(
        --prefix LD_LIBRARY_PATH : ${rpath}:$out/opt/Orca
        --prefix PATH : ${binpath}
      )
    '';

    meta = with lib; {
      description = "Next-gen IDE for parallel agentic development";
      homepage = "https://github.com/stablyai/orca";
      license = licenses.mit;
      mainProgram = "orca";
      platforms = ["x86_64-linux"];
      sourceProvenance = with sourceTypes; [binaryNativeCode];
    };
  }
