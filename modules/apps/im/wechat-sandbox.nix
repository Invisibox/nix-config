{
  pkgs,
  basePackage,
}: let
  runScript = pkgs.writeShellScript "wechat-sandbox-run" ''
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

    exec ${basePackage}/bin/wechat "$@"
  '';
in
  pkgs.buildFHSEnvBubblewrap {
    pname = "wechat-sandboxed";
    version =
      if basePackage ? version
      then basePackage.version
      else "unstable";

    executableName = "wechat";
    runScript = "${runScript}";
    targetPkgs = _: [basePackage];

    extraInstallCommands = ''
      if [ -d "${basePackage}/share" ]; then
        cp -rL "${basePackage}/share" "$out/share"
        chmod -R u+w "$out/share" || true
      fi

      if [ -f "$out/share/applications/wechat.desktop" ]; then
        sed -i "s|^Exec=.*|Exec=$out/bin/wechat %U|" "$out/share/applications/wechat.desktop"
        sed -i "s|^TryExec=.*|TryExec=$out/bin/wechat|" "$out/share/applications/wechat.desktop"
        sed -i "s|^Name=.*|Name=WeChat|" "$out/share/applications/wechat.desktop"
        sed -i "s|^Name\[zh_CN\]=.*|Name[zh_CN]=WeChat|" "$out/share/applications/wechat.desktop"
        sed -i "s|^Name\[zh_TW\]=.*|Name[zh_TW]=WeChat|" "$out/share/applications/wechat.desktop"
      fi
    '';

    extraPreBwrapCmds = ''
      DOCUMENTS_DIR="''${XDG_DOCUMENTS_DIR:-$HOME/Documents}"
      DOWNLOADS_DIR="''${XDG_DOWNLOAD_DIR:-$HOME/Downloads}"

      DOCUMENTS_DIR="$(readlink -m -- "''${DOCUMENTS_DIR}")"
      DOWNLOADS_DIR="$(readlink -m -- "''${DOWNLOADS_DIR}")"

      WECHAT_DATA_DIR="''${WECHAT_DATA_DIR:-''${DOCUMENTS_DIR}/WeChat_Data}"
      WECHAT_DATA_DIR="$(readlink -m -- "''${WECHAT_DATA_DIR}")"
      WECHAT_FILES_DIR="''${WECHAT_DATA_DIR}/xwechat_files"
      WECHAT_HOME_DIR="''${WECHAT_DATA_DIR}/home"

      mkdir -p "''${DOCUMENTS_DIR}" "''${DOWNLOADS_DIR}" "''${WECHAT_FILES_DIR}" "''${WECHAT_HOME_DIR}"
    '';

    extraBwrapArgs = [
      "--tmpfs /home"
      "--tmpfs /root"
      "--bind \${WECHAT_HOME_DIR} \${HOME}"
      "--bind \${WECHAT_FILES_DIR} \${WECHAT_FILES_DIR}"
      "--bind \${DOCUMENTS_DIR} \${DOCUMENTS_DIR}"
      "--bind \${DOWNLOADS_DIR} \${DOWNLOADS_DIR}"
      "--chdir \${HOME}"
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
        description = "Sandboxed WeChat Universal (HOME isolated; host access limited to Documents/Downloads).";
      };
  }
