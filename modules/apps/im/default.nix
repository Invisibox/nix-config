{
  lib,
  config,
  pkgs,
  username,
  ...
}: let
  cfg = config.im;
  wechatBasePackage = cfg.wechatBasePackage;
  qqBasePackage = cfg.qqPackage;
  wechatRunScript = pkgs.writeShellScript "wechat-sandbox-run" ''
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

    exec ${wechatBasePackage}/bin/wechat "$@"
  '';

  qqRunScript = pkgs.writeShellScript "qq-sandbox-run" ''
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

    exec ${qqBasePackage}/bin/qq "$@"
  '';

  wechatSandboxed = pkgs.buildFHSEnvBubblewrap {
    pname = "wechat-sandboxed";
    version =
      if wechatBasePackage ? version
      then wechatBasePackage.version
      else "unstable";

    executableName = "wechat";
    runScript = "${wechatRunScript}";
    targetPkgs = _: [wechatBasePackage];

    extraInstallCommands = ''
      if [ -d "${wechatBasePackage}/share" ]; then
        cp -rL "${wechatBasePackage}/share" "$out/share"
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
      (wechatBasePackage.meta or {})
      // {
        description = "Sandboxed WeChat Universal (HOME isolated; host access limited to Documents/Downloads).";
      };
  };

  qqSandboxed = pkgs.buildFHSEnvBubblewrap {
    pname = "qq-sandboxed";
    version =
      if qqBasePackage ? version
      then qqBasePackage.version
      else "unstable";

    executableName = "qq";
    runScript = "${qqRunScript}";
    targetPkgs = _: [qqBasePackage];

    extraInstallCommands = ''
      if [ -d "${qqBasePackage}/share" ]; then
        cp -rL "${qqBasePackage}/share" "$out/share"
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
      (qqBasePackage.meta or {})
      // {
        description = "Sandboxed QQ (HOME isolated; host access limited to Documents/Downloads).";
      };
  };
in {
  options.im = {
    enable = lib.mkEnableOption "Enable sandboxed WeChat and QQ managed by Home Manager";

    wechatBasePackage = lib.mkOption {
      type = lib.types.package;
      default = pkgs.wechat;
      description = "Base WeChat package to sandbox (default: WeChat Universal).";
    };

    wechatPackage = lib.mkOption {
      type = lib.types.package;
      default = wechatSandboxed;
      description = "Final WeChat package installed for the user.";
    };

    qqPackage = lib.mkOption {
      type = lib.types.package;
      default = pkgs.qq;
      description = "Base QQ package wrapped in a strict bubblewrap sandbox.";
    };
  };

  config = lib.mkIf cfg.enable {
    home-manager.users.${username}.home.packages = [
      cfg.wechatPackage
      qqSandboxed
    ];
  };
}
