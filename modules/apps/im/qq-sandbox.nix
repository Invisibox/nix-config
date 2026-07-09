{
  pkgs,
  basePackage,
}: let
  runScript = pkgs.writeShellScript "qq-sandbox-run" ''
    # Keep QQ on X11/XWayland path for better IME behavior (single-line preedit).
    unset WAYLAND_DISPLAY
    export NIXOS_OZONE_WL=""
    export ELECTRON_OZONE_PLATFORM_HINT=x11
    export QT_QPA_PLATFORM=xcb

    if [[ "''${XMODIFIERS:-}" == *fcitx* ]]; then
      export QT_IM_MODULE=fcitx
      export GTK_IM_MODULE=fcitx
      export XMODIFIERS=@im=fcitx
    elif [[ "''${XMODIFIERS:-}" == *ibus* ]]; then
      export QT_IM_MODULE=ibus
      export GTK_IM_MODULE=ibus
      export IBUS_USE_PORTAL=1
      export XMODIFIERS=@im=ibus
    fi

    exec ${basePackage}/bin/qq "$@"
  '';
in
  pkgs.buildFHSEnvBubblewrap {
    pname = "qq-sandboxed";
    version =
      if basePackage ? version
      then basePackage.version
      else "unstable";

    executableName = "qq";
    runScript = "${runScript}";
    targetPkgs = _: [basePackage];

    extraInstallCommands = ''
      if [ -d "${basePackage}/share" ]; then
        cp -rL "${basePackage}/share" "$out/share"
        chmod -R u+w "$out/share" || true
      fi

      if [ -f "$out/share/applications/qq.desktop" ]; then
        sed -i "s|^Exec=.*|Exec=$out/bin/qq %U|" "$out/share/applications/qq.desktop"
        sed -i "s|^TryExec=.*|TryExec=$out/bin/qq|" "$out/share/applications/qq.desktop"
      fi
    '';

    extraPreBwrapCmds = ''
      DOCUMENTS_DIR="''${XDG_DOCUMENTS_DIR:-$HOME/Documents}"
      DOWNLOADS_DIR="''${XDG_DOWNLOAD_DIR:-$HOME/Downloads}"

      DOCUMENTS_DIR="$(readlink -m -- "''${DOCUMENTS_DIR}")"
      DOWNLOADS_DIR="$(readlink -m -- "''${DOWNLOADS_DIR}")"

      QQ_DATA_DIR="''${QQ_DATA_DIR:-''${DOCUMENTS_DIR}/QQ_Data}"
      QQ_DATA_DIR="$(readlink -m -- "''${QQ_DATA_DIR}")"
      QQ_HOME_DIR="''${QQ_DATA_DIR}/home"

      mkdir -p "''${DOCUMENTS_DIR}" "''${DOWNLOADS_DIR}" "''${QQ_HOME_DIR}"
    '';

    # Keep host-visible paths minimal with sandboxed home isolation.
    extraBwrapArgs = [
      "--tmpfs /home"
      "--tmpfs /root"
      "--bind \${QQ_HOME_DIR} \${HOME}"
      "--bind \${DOCUMENTS_DIR} \${DOCUMENTS_DIR}"
      "--bind \${DOWNLOADS_DIR} \${DOWNLOADS_DIR}"
      "--chdir \${HOME}"
      "--setenv QT_QPA_PLATFORM xcb"
      "--setenv QT_AUTO_SCREEN_SCALE_FACTOR 1"
    ];

    unshareUser = true;
    unshareIpc = true;
    unsharePid = true;
    unshareNet = false;
    unshareUts = true;
    unshareCgroup = true;
    privateTmp = true;

    meta =
      (basePackage.meta or {})
      // {
        description = "Sandboxed QQ (HOME isolated; host access limited to Documents/Downloads).";
      };
  }
