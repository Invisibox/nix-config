{
  pkgs,
  basePackage,
}: let
  runScript = pkgs.writeShellScript "baidunetdisk-sandbox-run" ''
    unset ELECTRON_RUN_AS_NODE
    export TMPDIR="/tmp/baidunetdisk"
    mkdir -p "$TMPDIR"
    exec ${basePackage}/opt/baidunetdisk/baidunetdisk --no-sandbox "$@"
  '';
in
  pkgs.buildFHSEnvBubblewrap {
    pname = "baidunetdisk-sandboxed";
    version =
      if basePackage ? version
      then basePackage.version
      else "unstable";

    executableName = "baidunetdisk";
    runScript = "${runScript}";
    targetPkgs = _: [basePackage] ++ (basePackage.passthru.runtimeDeps or []);

    extraInstallCommands = ''
      if [ -d "${basePackage}/share" ]; then
        cp -rL "${basePackage}/share" "$out/share"
        chmod -R u+w "$out/share" || true
      fi

      desktop="$out/share/applications/baidunetdisk.desktop"
      if [ -f "$desktop" ]; then
        sed -i "s|^Exec=.*|Exec=$out/bin/baidunetdisk %U|" "$desktop"

        if grep -q '^TryExec=' "$desktop"; then
          sed -i "s|^TryExec=.*|TryExec=$out/bin/baidunetdisk|" "$desktop"
        else
          echo "TryExec=$out/bin/baidunetdisk" >> "$desktop"
        fi
      fi
    '';

    extraPreBwrapCmds = ''
      DOCUMENTS_DIR="''${XDG_DOCUMENTS_DIR:-$HOME/Documents}"
      DOCUMENTS_DIR="$(readlink -m -- "''${DOCUMENTS_DIR}")"
      BAIDUNETDISK_DATA_DIR="''${DOCUMENTS_DIR}/BaiduNetdisk_Data"
      BAIDUNETDISK_HOME_DIR="''${BAIDUNETDISK_DATA_DIR}/home"

      mkdir -p "''${BAIDUNETDISK_HOME_DIR}"
    '';

    # The persistent virtual home and all user-selected files live under this one directory.
    extraBwrapArgs = [
      "--tmpfs /home"
      "--tmpfs /root"
      "--tmpfs /dev/shm"
      "--bind \${BAIDUNETDISK_HOME_DIR} \${HOME}"
      "--bind \${BAIDUNETDISK_DATA_DIR} \${BAIDUNETDISK_DATA_DIR}"
      "--chdir \${HOME}"
    ];

    unshareUser = true;
    # Flatpak shares IPC for this client; its native service uses it at startup.
    unshareIpc = false;
    # The vendor main process deliberately keeps netdisk_service outside its
    # process group; a PID namespace kills that helper when Electron exits.
    unsharePid = false;
    unshareNet = false;
    unshareUts = true;
    unshareCgroup = true;
    privateTmp = true;
    chdirToPwd = false;

    meta =
      (basePackage.meta or {})
      // {
        description = "Sandboxed Baidu Netdisk (HOME and host files isolated to Documents/BaiduNetdisk_Data).";
      };
  }
