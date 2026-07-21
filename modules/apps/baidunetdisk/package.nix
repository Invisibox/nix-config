{
  lib,
  pkgs,
}: let
  pname = "baidunetdisk";
  version = "8.6.0";

  # Mirror Flathub's compatibility stack. The vendor binary is intentionally
  # left unpatched and is run only from the Bubblewrap FHS environment.
  runtimeDeps = with pkgs; [
    adwaita-icon-theme
    alsa-lib
    at-spi2-atk
    at-spi2-core
    atk
    atkmm
    cairo
    cairomm
    cups
    dbus
    expat
    fontconfig
    freetype
    gdk-pixbuf
    glib
    glibmm
    gsettings-desktop-schemas
    gtk2
    gtk3
    gtkmm2
    libappindicator-gtk3
    libdrm
    libGL
    libgbm
    libnotify
    libsecret
    libsigcxx
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
    libXt
    libxtst
    nspr
    nss
    pango
    pangomm
    procps
    stdenv.cc.cc.lib
    udev
    vulkan-loader
    wayland
    xdg-utils
    zlib
  ];

  src = pkgs.fetchurl {
    url = "https://pkg-ant.baidu.com/issue/netdisk/LinuxGuanjia/8.6.0/baidunetdisk-8.6.0.x86_64.rpm";
    hash = "sha256-1REe7QixUJlbTnmRIRXSctgxF7OUkRItZEC5U1Po4r4=";
  };
in
  pkgs.stdenvNoCC.mkDerivation {
    inherit pname version src;

    nativeBuildInputs = [
      pkgs.cpio
      pkgs.rpm
    ];

    dontConfigure = true;
    dontBuild = true;
    dontPatchELF = true;

    unpackPhase = ''
      runHook preUnpack
      rpm2cpio "$src" | cpio --extract --make-directories --no-absolute-filenames
      runHook postUnpack
    '';

    installPhase = ''
      runHook preInstall

      mkdir -p "$out/bin" "$out/share/applications"
      cp -R opt "$out/"
      ln -s "$out/opt/baidunetdisk/baidunetdisk" "$out/bin/baidunetdisk"

      install -Dm644 "$out/opt/baidunetdisk/baidunetdisk.desktop" \
        "$out/share/applications/baidunetdisk.desktop"
      substituteInPlace "$out/share/applications/baidunetdisk.desktop" \
        --replace-fail "/opt/baidunetdisk/baidunetdisk" "baidunetdisk" \
        --replace-fail "Name=baidunetdisk" "Name=Baidu Netdisk" \
        --replace-fail "Name[zh_CN]=百度网盘" "Name[zh_CN]=Baidu Netdisk" \
        --replace-fail "Name[zh_TW]=百度网盘" "Name[zh_TW]=Baidu Netdisk"

      runHook postInstall
    '';

    passthru.runtimeDeps = runtimeDeps;

    meta = with lib; {
      description = "Baidu Netdisk desktop client";
      homepage = "https://pan.baidu.com/";
      license = licenses.unfree;
      mainProgram = "baidunetdisk";
      platforms = ["x86_64-linux"];
      sourceProvenance = with sourceTypes; [binaryNativeCode];
    };
  }
