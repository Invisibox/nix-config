{
  lib,
  config,
  pkgs,
  inputs,
  username,
  ...
}: let
  cfg = config.wemeet;
in {
  options.wemeet = {
    enable = lib.mkEnableOption "Enable sandboxed WeMeet";

    basePackage = lib.mkOption {
      type = lib.types.package;
      default = pkgs.wemeet;
      description = "Base WeMeet package used to build sandboxed launcher.";
    };

    package = lib.mkOption {
      type = lib.types.package;
      default = pkgs.wemeet;
      description = "Final WeMeet package installed via Home Manager.";
    };
  };

  config = lib.mkIf cfg.enable (let
    pkgsStable = import inputs.nixpkgs-stable {
      inherit (pkgs.stdenv.hostPlatform) system;
      config.allowUnfree = true;
    };

    # Keep stable XWayland startup path for better runtime compatibility.
    wemeetX11 = pkgs.symlinkJoin {
      name = "wemeet-native-x11";
      paths = [pkgsStable.wemeet];
      nativeBuildInputs = [pkgs.makeWrapper];
      postBuild = ''
        rm -f "$out/bin/wemeet"
        makeWrapper "${pkgsStable.wemeet}/bin/wemeet-xwayland" "$out/bin/wemeet" \
          --set QT_QPA_PLATFORM "xcb" \
          --set SDL_VIDEODRIVER "x11" \
          --set GDK_BACKEND "x11" \
          --unset WAYLAND_DISPLAY \
          --set __EGL_VENDOR_LIBRARY_FILENAMES "${pkgsStable.mesa}/share/glvnd/egl_vendor.d/50_mesa.json"
      '';
    };

    wemeetBase = cfg.basePackage;

    wemeetRunScript = pkgs.writeShellScript "wemeet-sandbox-run" ''
      # Keep WeMeet on X11/XWayland path for IME/input behavior.
      unset WAYLAND_DISPLAY
      export NIXOS_OZONE_WL=""
      export ELECTRON_OZONE_PLATFORM_HINT=x11
      export QT_QPA_PLATFORM=xcb
      export SDL_VIDEODRIVER=x11
      export GDK_BACKEND=x11

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

      exec ${wemeetBase}/bin/wemeet "$@"
    '';

    wemeetSandboxed = pkgs.buildFHSEnvBubblewrap {
      pname = "wemeet-sandboxed";
      version =
        if wemeetBase ? version
        then wemeetBase.version
        else "unstable";

      executableName = "wemeet";
      runScript = "${wemeetRunScript}";
      targetPkgs = _: [wemeetBase];

      extraInstallCommands = ''
        if [ -d "${wemeetBase}/share" ]; then
          cp -rL "${wemeetBase}/share" "$out/share"
          chmod -R u+w "$out/share" || true
        fi

        desktop="$out/share/applications/wemeetapp.desktop"
        if [ -f "$desktop" ]; then
          sed -i "s|^Exec=.*|Exec=$out/bin/wemeet %u|" "$desktop"

          if grep -q '^TryExec=' "$desktop"; then
            sed -i "s|^TryExec=.*|TryExec=$out/bin/wemeet|" "$desktop"
          else
            echo "TryExec=$out/bin/wemeet" >> "$desktop"
          fi

          if grep -q '^Name=' "$desktop"; then
            sed -i "s|^Name=.*|Name=WeMeet|" "$desktop"
          else
            echo "Name=WeMeet" >> "$desktop"
          fi

          if grep -q '^Name\[zh_CN\]=' "$desktop"; then
            sed -i "s|^Name\[zh_CN\]=.*|Name[zh_CN]=WeMeet|" "$desktop"
          else
            echo "Name[zh_CN]=WeMeet" >> "$desktop"
          fi

          if grep -q '^Name\[zh_TW\]=' "$desktop"; then
            sed -i "s|^Name\[zh_TW\]=.*|Name[zh_TW]=WeMeet|" "$desktop"
          else
            echo "Name[zh_TW]=WeMeet" >> "$desktop"
          fi
        fi
      '';

      extraPreBwrapCmds = ''
        DOCUMENTS_DIR="''${XDG_DOCUMENTS_DIR:-$HOME/Documents}"
        DOWNLOADS_DIR="''${XDG_DOWNLOAD_DIR:-$HOME/Downloads}"

        DOCUMENTS_DIR="$(readlink -m -- "''${DOCUMENTS_DIR}")"
        DOWNLOADS_DIR="$(readlink -m -- "''${DOWNLOADS_DIR}")"

        WEMEET_DATA_DIR="''${WEMEET_DATA_DIR:-''${DOCUMENTS_DIR}/WeMeet_Data}"
        WEMEET_DATA_DIR="$(readlink -m -- "''${WEMEET_DATA_DIR}")"
        WEMEET_HOME_DIR="''${WEMEET_DATA_DIR}/home"

        mkdir -p "''${DOCUMENTS_DIR}" "''${DOWNLOADS_DIR}" "''${WEMEET_HOME_DIR}"
      '';

      extraBwrapArgs = [
        "--tmpfs /home"
        "--tmpfs /root"
        "--bind \${WEMEET_HOME_DIR} \${HOME}"
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
        (wemeetBase.meta or {})
        // {
          description = "Sandboxed WeMeet (HOME isolated; host access limited to Documents/Downloads).";
        };
    };
  in {
    # Default to stable wrapped XWayland WeMeet as sandbox base package.
    wemeet.basePackage = lib.mkDefault wemeetX11;

    # Install sandboxed WeMeet by default.
    wemeet.package = lib.mkDefault wemeetSandboxed;

    home-manager.users.${username}.home.packages = [
      cfg.package
    ];
  });
}
