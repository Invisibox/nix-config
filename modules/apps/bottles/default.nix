{
  lib,
  config,
  username,
  pkgs,
  ...
}: let
  cfg = config.local.apps.bottles;
  bottlesPkgs = pkgs.extend (_final: prev: {
    openldap = prev.openldap.overrideAttrs (_: {
      doCheck = false;
    });
  });
  archiveNativeBuildInputs = with pkgs; [
    gnutar
    gzip
    unzip
    xz
  ];
  winebridgeVersion = "1.2.0";
  winebridgeReleaseTag = "1.2.0";
  winebridgeAsset = "WineBridge-75aa25e.tar.xz";
  winebridgeHash = "sha256-81yuP3fAtCRYw8rNIjd7zswkTNcQxQbICkRkYd1eBrw=";
  winebridge = pkgs.stdenvNoCC.mkDerivation {
    pname = "bottles-winebridge";
    version = winebridgeVersion;
    src = pkgs.fetchurl {
      url = "https://github.com/bottlesdevs/winebridge/releases/download/${winebridgeReleaseTag}/${winebridgeAsset}";
      hash = winebridgeHash;
    };
    nativeBuildInputs = archiveNativeBuildInputs;
    sourceRoot = ".";
    dontConfigure = true;
    dontBuild = true;
    installPhase = ''
      runHook preInstall

      mkdir -p "$out/share/bottles/winebridge"
      cp -a ./. "$out/share/bottles/winebridge/"

      if [ ! -s "$out/share/bottles/winebridge/VERSION" ]; then
        printf '%s\n' "${winebridgeVersion}" > "$out/share/bottles/winebridge/VERSION"
      fi

      runHook postInstall
    '';
  };
  mkBottlesComponent = {
    pname,
    url,
    hash,
    installPath,
    sourceDir ? "",
    ...
  }:
    pkgs.stdenvNoCC.mkDerivation {
      name = pname;
      src = pkgs.fetchurl {
        inherit url hash;
      };
      nativeBuildInputs = archiveNativeBuildInputs;
      sourceRoot = ".";
      dontConfigure = true;
      dontBuild = true;
      installPhase = ''
        runHook preInstall

        dest="$out/share/bottles/${installPath}"
        mkdir -p "$dest"

        if [ -n "${sourceDir}" ] && [ -d "${sourceDir}" ]; then
          cp -a "${sourceDir}/." "$dest/"
        else
          cp -a ./. "$dest/"
        fi

        runHook postInstall
      '';
    };
  mkBottlesRunner = {
    pname,
    url,
    hash,
    runnerName,
    sourceDir ? "",
    ...
  }:
    pkgs.stdenvNoCC.mkDerivation {
      name = pname;
      src = pkgs.fetchurl {
        inherit url hash;
      };
      nativeBuildInputs = archiveNativeBuildInputs;
      sourceRoot = ".";
      dontConfigure = true;
      dontBuild = true;
      installPhase = ''
        runHook preInstall

        mkdir -p "$out/share/steam/compatibilitytools.d/${runnerName}"

        if [ -n "${sourceDir}" ] && [ -d "${sourceDir}" ]; then
          cp -a "${sourceDir}/." "$out/share/steam/compatibilitytools.d/${runnerName}/"
        else
          cp -a ./. "$out/share/steam/compatibilitytools.d/${runnerName}/"
        fi

        chmod -R u+w "$out/share/steam/compatibilitytools.d/${runnerName}"
        find "$out/share/steam/compatibilitytools.d/${runnerName}" \
          -type f \
          -name winemenubuilder.exe \
          -exec sh -eu -c '
            for winemenubuilder do
              mv "$winemenubuilder" "$winemenubuilder.lock"
            done
          ' sh {} +

        runHook postInstall
      '';
    };
  runtimeComponentInfo = {
    name = "runtime-0.6.3";
    url = "https://github.com/bottlesdevs/runtime/releases/download/0.6.3/runtime-0.6.3.tar.gz";
    hash = "sha256-13SbSJJ714LhKONyodcIUTP74wDrkZMTTrgh9hvF+tY=";
    sourceDir = "runtime-0.6.3";
  };
  dxvkComponentInfo = {
    name = "dxvk-3.0.1";
    url = "https://github.com/doitsujin/dxvk/releases/download/v3.0.1/dxvk-3.0.1.tar.gz";
    hash = "sha256-vrtihNtZBTW3sAXBAuv2hQyYhCz/D97Zqst0urrhTEk=";
    sourceDir = "dxvk-3.0.1";
  };
  vkd3dComponentInfo = {
    name = "vkd3d-proton-3.0.1";
    url = "https://github.com/bottlesdevs/components/releases/download/vkd3d-proton-3.0.1/vkd3d-proton-3.0.1.tar.gz";
    hash = "sha256-Fx9L+Vy56upSSc0/IhHmAtlxopKnLEYuwpNEkRK2c/M=";
    sourceDir = "vkd3d-proton-3.0.1";
  };
  nvapiComponentInfo = {
    name = "dxvk-nvapi-v0.9.2";
    url = "https://github.com/bottlesdevs/components/releases/download/dxvk-nvapi-v0.9.2/dxvk-nvapi-v0.9.2.tar.gz";
    hash = "sha256-fXV1wa+j+UtRfZjGrSyaznf3Orzlvr3LuZikSKPB7E0=";
    sourceDir = "dxvk-nvapi-v0.9.2";
  };
  latencyflexComponentInfo = {
    name = "latencyflex-v0.1.1";
    url = "https://github.com/ishitatsuyuki/LatencyFleX/releases/download/v0.1.1/latencyflex-v0.1.1.tar.xz";
    hash = "sha256-yZLr0vQ8matKhKb/zmktmq5MwlcVNqWFSuLnm2lR54o=";
    sourceDir = "latencyflex-v0.1.1";
  };
  caffeRunnerInfo = {
    name = "caffe-9.7";
    url = "https://github.com/bottlesdevs/wine/releases/download/caffe-9.7/caffe-9.7-x86_64.tar.xz";
    hash = "sha256-cRfMHG1OOBheLoXhRqouRU9mK+hTBI/G0f4a9d2FYFc=";
    runnerName = "caffe-nix";
    sourceDir = "caffe-9.7-x86_64";
  };
  sodaRunnerInfo = {
    name = "soda-9.0-1";
    url = "https://github.com/bottlesdevs/wine/releases/download/soda-9.0-1/soda-9.0-1-x86_64.tar.xz";
    hash = "sha256-w4/grTwSpJth7B/K6lxdjaSj0a/FmRvv4q9rEl8BTCg=";
    runnerName = "soda-nix";
    sourceDir = "soda-9.0-1-x86_64";
  };
  runtimeComponent = mkBottlesComponent (runtimeComponentInfo
    // {
      pname = "bottles-${runtimeComponentInfo.name}";
      installPath = "runtimes/${runtimeComponentInfo.name}";
    });
  dxvkComponent = mkBottlesComponent (dxvkComponentInfo
    // {
      pname = "bottles-${dxvkComponentInfo.name}";
      installPath = "dxvk/${dxvkComponentInfo.name}";
    });
  vkd3dComponent = mkBottlesComponent (vkd3dComponentInfo
    // {
      pname = "bottles-${vkd3dComponentInfo.name}";
      installPath = "vkd3d/${vkd3dComponentInfo.name}";
    });
  nvapiComponent = mkBottlesComponent (nvapiComponentInfo
    // {
      pname = "bottles-${nvapiComponentInfo.name}";
      installPath = "nvapi/${nvapiComponentInfo.name}";
    });
  latencyflexComponent = mkBottlesComponent (latencyflexComponentInfo
    // {
      pname = "bottles-${latencyflexComponentInfo.name}";
      installPath = "latencyflex/${latencyflexComponentInfo.name}";
    });
  caffeRunner = mkBottlesRunner ({
      pname = caffeRunnerInfo.name;
    }
    // caffeRunnerInfo);
  sodaRunner = mkBottlesRunner ({
      pname = sodaRunnerInfo.name;
    }
    // sodaRunnerInfo);
in {
  options = {
    local.apps.bottles = {
      enable = lib.mkEnableOption "Enable Bottles in home-manager";
    };
  };
  config = lib.mkIf cfg.enable {
    home-manager.users.${username} = {
      config,
      pkgs,
      ...
    }: {
      home = {
        file = {
          bottles-links-caffe = {
            source = "${caffeRunner}/share/steam/compatibilitytools.d/caffe-nix";
            target = "${config.xdg.dataHome}/bottles/runners/caffe-nix";
          };
          bottles-links-soda = {
            source = "${sodaRunner}/share/steam/compatibilitytools.d/soda-nix";
            target = "${config.xdg.dataHome}/bottles/runners/soda-nix";
          };
          bottles-winebridge-version = {
            source = "${winebridge}/share/bottles/winebridge/VERSION";
            target = "${config.xdg.dataHome}/bottles/winebridge/VERSION";
            force = true;
          };
          bottles-winebridge-exe = {
            source = "${winebridge}/share/bottles/winebridge/WineBridge.exe";
            target = "${config.xdg.dataHome}/bottles/winebridge/WineBridge.exe";
            force = true;
          };
          bottles-runtime = {
            source = "${runtimeComponent}/share/bottles/runtimes/${runtimeComponentInfo.name}";
            target = "${config.xdg.dataHome}/bottles/runtimes/${runtimeComponentInfo.name}";
          };
          bottles-dxvk = {
            source = "${dxvkComponent}/share/bottles/dxvk/${dxvkComponentInfo.name}";
            target = "${config.xdg.dataHome}/bottles/dxvk/${dxvkComponentInfo.name}";
          };
          bottles-vkd3d = {
            source = "${vkd3dComponent}/share/bottles/vkd3d/${vkd3dComponentInfo.name}";
            target = "${config.xdg.dataHome}/bottles/vkd3d/${vkd3dComponentInfo.name}";
          };
          bottles-nvapi = {
            source = "${nvapiComponent}/share/bottles/nvapi/${nvapiComponentInfo.name}";
            target = "${config.xdg.dataHome}/bottles/nvapi/${nvapiComponentInfo.name}";
          };
          bottles-latencyflex = {
            source = "${latencyflexComponent}/share/bottles/latencyflex/${latencyflexComponentInfo.name}";
            target = "${config.xdg.dataHome}/bottles/latencyflex/${latencyflexComponentInfo.name}";
          };
          proton-links-proton-em-bottles = {
            source = pkgs.proton-em.steamcompattool;
            target = "${config.xdg.dataHome}/bottles/runners/proton-em-nix";
          };
          proton-links-proton-ge-bottles = {
            source = pkgs.proton-ge.steamcompattool;
            target = "${config.xdg.dataHome}/bottles/runners/proton-ge-nix";
          };
        };
        packages = [
          (bottlesPkgs.bottles.override {
            removeWarningPopup = true;
          })
          pkgs.vulkan-tools
        ];
      };
      xdg = {
        desktopEntries."com.usebottles.bottles" = {
          name = "Bottles";
          comment = "Run Windows software";
          exec = "env PROTON_ENABLE_HDR=1 PROTON_USE_WOW64=1 PIPEWIRE_NODE=Game PULSE_SINK=Game bottles %u";
          terminal = false;
          icon = "com.usebottles.bottles";
          type = "Application";
          startupNotify = true;
          categories = ["Utility"];
        };
        mimeApps.defaultApplications."x-scheme-handler/bottles" = [
          "com.usebottles.bottles.desktop"
        ];
      };
    };
  };
}
