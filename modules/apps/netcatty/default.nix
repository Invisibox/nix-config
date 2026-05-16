{
  lib,
  config,
  username,
  pkgs,
  ...
}: let
  cfg = config.netcatty;

  pname = "netcatty";
  version = "1.1.6";

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
    libcap
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
    zlib
  ];

  rpath = lib.makeLibraryPath deps + ":" + lib.makeSearchPathOutput "lib" "lib64" deps;
  binpath = lib.makeBinPath [pkgs.xdg-utils];

  src = pkgs.fetchurl {
    url = "https://github.com/binaricat/Netcatty/releases/download/v${version}/Netcatty-${version}-linux-amd64.deb";
    hash = "sha256-4IyBuzw1ICI7bWrehF0o5W1jYjGEI/jw1MiXDuyl2Rs=";
  };

  sharpLibvipsSrc = pkgs.fetchurl {
    url = "https://registry.npmjs.org/@img/sharp-libvips-linux-x64/-/sharp-libvips-linux-x64-1.2.4.tgz";
    hash = "sha256-Q8Ey9aMdwNOK/4N2/c5mtHYRGKRR5B36NvmCnZYHwHw=";
  };

  netcattyPackage = pkgs.stdenv.mkDerivation {
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

      app_dir="$out/opt/Netcatty"
      icon_src="$out/share/icons/hicolor/1024x1024/apps/netcatty.png"
      node_modules="$app_dir/resources/app.asar.unpacked/node_modules"
      sharp_libvips_dir="$node_modules/@img/sharp-libvips-linux-x64"

      for icon_size in 128 256 512; do
        install -d "$out/share/icons/hicolor/''${icon_size}x''${icon_size}/apps"
        magick "$icon_src" -resize "''${icon_size}x''${icon_size}" \
          "$out/share/icons/hicolor/''${icon_size}x''${icon_size}/apps/netcatty.png"
      done

      mkdir -p "$sharp_libvips_dir"
      tar -xzf ${sharpLibvipsSrc} --strip-components=1 -C "$sharp_libvips_dir"
      rm -rf "$node_modules/@img/sharp-linuxmusl-x64"
      rm -f "$node_modules/@serialport/bindings-cpp/prebuilds/linux-x64/"*musl.node

      chmod +x "$app_dir/netcatty"
      chmod +x "$app_dir/chrome_crashpad_handler"
      chmod +x "$app_dir/resources/mosh/mosh-client"
      chmod +x "$app_dir/resources/app.asar.unpacked/electron/cli/netcatty-tool-cli"

      makeWrapper "$app_dir/netcatty" "$out/bin/netcatty" \
        --unset ELECTRON_RUN_AS_NODE \
        --add-flags "--ozone-platform=x11"

      makeWrapper "$app_dir/resources/app.asar.unpacked/electron/cli/netcatty-tool-cli" \
        "$out/bin/netcatty-tool-cli" \
        --set NETCATTY_CLI_ELECTRON_EXEC_PATH "$app_dir/netcatty"

      substituteInPlace "$out/share/applications/netcatty.desktop" \
        --replace-fail "/opt/Netcatty/netcatty" "netcatty"

      runHook postInstall
    '';

    preFixup = ''
      addAutoPatchelfSearchPath "$out/opt/Netcatty"
      addAutoPatchelfSearchPath "$out/opt/Netcatty/resources/app.asar.unpacked/node_modules/@img/sharp-libvips-linux-x64/lib"

      gappsWrapperArgs+=(
        --prefix LD_LIBRARY_PATH : ${rpath}:$out/opt/Netcatty:$out/opt/Netcatty/resources/app.asar.unpacked/node_modules/@img/sharp-libvips-linux-x64/lib
        --prefix PATH : ${binpath}
      )
    '';

    meta = {
      description = "Modern SSH manager and terminal app";
      homepage = "https://github.com/binaricat/Netcatty";
      license = lib.licenses.gpl3Plus;
      mainProgram = "netcatty";
      platforms = ["x86_64-linux"];
      sourceProvenance = with lib.sourceTypes; [binaryNativeCode];
    };
  };
in {
  options.netcatty = {
    enable = lib.mkEnableOption "Enable Netcatty via Home Manager";

    package = lib.mkOption {
      type = lib.types.package;
      default = netcattyPackage;
      description = "The Netcatty package installed for the user.";
    };
  };

  config = lib.mkIf cfg.enable {
    home-manager.users.${username}.home.packages = [
      cfg.package
    ];
  };
}
