{
  lib,
  config,
  pkgs,
  inputs,
  ...
}: let
  cfg = config.local.apps.wemeet;
  localUserName = config.local.user.name;
in {
  options.local.apps.wemeet = {
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

    # Follow Flathub's native Wayland path. The upstream client supports
    # Wayland screensharing now, so do not inject the obsolete X11 capture hook.
    wemeetNativeWayland = pkgsStable.wemeet.overrideAttrs (old: {
      pname = "wemeet-native-wayland";
      postFixup =
        (old.postFixup or "")
        + ''
            rm -f "$out/app/wemeet/bin/xcast.conf"
            printf '%s\n' '{}' > "$out/app/wemeet/bin/xcast.conf"

          for launcher in "$out/bin/wemeet" "$out/bin/wemeet-xwayland"; do
            sed -i '/wemeet-wayland-screenshare/d' "$launcher"
            if grep -q 'wemeet-wayland-screenshare' "$launcher"; then
              echo "failed to remove obsolete wemeet-wayland-screenshare hook" >&2
              exit 1
            fi
          done
        '';
    });

    wemeetBase = cfg.basePackage;

    wemeetRunScript = pkgs.writeShellScript "wemeet-sandbox-run" ''
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
      chdirToPwd = false;

      meta =
        (wemeetBase.meta or {})
        // {
          description = "Sandboxed WeMeet (HOME isolated; host access limited to Documents/Downloads).";
        };
    };
  in {
    # Default to stable WeMeet using its native Wayland screenshare path.
    local.apps.wemeet.basePackage = lib.mkDefault wemeetNativeWayland;

    # Install sandboxed WeMeet by default.
    local.apps.wemeet.package = lib.mkDefault wemeetSandboxed;

    home-manager.users.${localUserName}.home.packages = [
      cfg.package
    ];
  });
}
