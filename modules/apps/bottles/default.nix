{
  lib,
  config,
  username,
  pkgs,
  ...
}:
let
  cfg = config.bottles;
  bottlesPkgs = pkgs.extend (_final: prev: {
    openldap = prev.openldap.overrideAttrs (_: {
      doCheck = false;
    });
  });
  winebridgeVersion = "1.2.0";
  winebridgeReleaseTag = "1.2.0";
  winebridgeAsset = "WineBridge-75aa25e.tar.xz";
  winebridgeHash = "sha256-DxxBS2IWZRsSXzZ5QO6rmJvg4S49l9SSvQzcmIFTiF4=";
  winebridge = pkgs.runCommand "bottles-winebridge-${winebridgeVersion}" {
    src = pkgs.fetchzip {
      url = "https://github.com/bottlesdevs/winebridge/releases/download/${winebridgeReleaseTag}/${winebridgeAsset}";
      hash = winebridgeHash;
      stripRoot = false;
    };
  } ''
    set -euo pipefail

    mkdir -p "$out/share/bottles/winebridge"
    cp -a "$src/." "$out/share/bottles/winebridge/"

    if [ ! -s "$out/share/bottles/winebridge/VERSION" ]; then
      printf '%s\n' "${winebridgeVersion}" > "$out/share/bottles/winebridge/VERSION"
    fi
  '';
  mkBottlesComponent =
    {
      pname,
      url,
      hash,
      installPath,
      sourceDir ? "",
      ...
    }:
    pkgs.runCommand pname {
      src = pkgs.fetchzip {
        inherit url hash;
      };
    } ''
      set -euo pipefail

      dest="$out/share/bottles/${installPath}"
      mkdir -p "$dest"

      if [ -n "${sourceDir}" ] && [ -d "$src/${sourceDir}" ]; then
        cp -a "$src/${sourceDir}/." "$dest/"
      else
        cp -a "$src/." "$dest/"
      fi
    '';
  mkBottlesRunner =
    {
      pname,
      url,
      hash,
      runnerName,
      sourceDir ? "",
      ...
    }:
    pkgs.runCommand pname {
      src = pkgs.fetchzip {
        inherit url hash;
        stripRoot = false;
      };
    } ''
      set -euo pipefail

      mkdir -p "$out/share/steam/compatibilitytools.d/${runnerName}"

      if [ -n "${sourceDir}" ] && [ -d "$src/${sourceDir}" ]; then
        cp -a "$src/${sourceDir}/." "$out/share/steam/compatibilitytools.d/${runnerName}/"
      else
        cp -a "$src/." "$out/share/steam/compatibilitytools.d/${runnerName}/"
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
    '';
  runtimeComponentInfo = {
    name = "runtime-0.6.3";
    url = "https://github.com/bottlesdevs/runtime/releases/download/0.6.3/runtime-0.6.3.tar.gz";
    hash = "sha256-ro9DbjGdsf6NuPnbzbd+Ih/wBvpJnYoj1JmvPVwXtic=";
    sourceDir = "runtime-0.6.3";
  };
  dxvkComponentInfo = {
    name = "dxvk-2.7.1";
    url = "https://github.com/doitsujin/dxvk/releases/download/v2.7.1/dxvk-2.7.1.tar.gz";
    hash = "sha256-Sk8CybV50Ec78DCOfXDL+fCrp0ikwJwybtKWiqOlEDU=";
    sourceDir = "dxvk-2.7.1";
  };
  vkd3dComponentInfo = {
    name = "vkd3d-proton-3.0.1";
    url = "https://github.com/bottlesdevs/components/releases/download/vkd3d-proton-3.0.1/vkd3d-proton-3.0.1.tar.gz";
    hash = "sha256-xHJFtVDD/ZHVHF2Fn7TEEX0fMUWJvujNyNt2Xyw9F7o=";
    sourceDir = "vkd3d-proton-3.0.1";
  };
  nvapiComponentInfo = {
    name = "dxvk-nvapi-v0.9.1";
    url = "https://github.com/bottlesdevs/components/releases/download/dxvk-nvapi-v0.9.1/dxvk-nvapi-v0.9.1.tar.gz";
    hash = "sha256-W5uYE9fjylH2eQFdEH8oELD23h61Jda2g61KJmkmZSI=";
    sourceDir = "dxvk-nvapi-v0.9.1";
  };
  latencyflexComponentInfo = {
    name = "latencyflex-v0.1.1";
    url = "https://github.com/ishitatsuyuki/LatencyFleX/releases/download/v0.1.1/latencyflex-v0.1.1.tar.xz";
    hash = "sha256-c/o0wcTZ8TJwLzUHlvmS/kcoOPlfCPHupWFABTVXtok=";
    sourceDir = "latencyflex-v0.1.1";
  };
  caffeRunnerInfo = {
    name = "caffe-9.7";
    url = "https://github.com/bottlesdevs/wine/releases/download/caffe-9.7/caffe-9.7-x86_64.tar.xz";
    hash = "sha256-yYcXJ6TejgasV6F9M4X3QEC7b0ectes5rRQXGMR48No=";
    runnerName = "caffe-nix";
    sourceDir = "caffe-9.7-x86_64";
  };
  sodaRunnerInfo = {
    name = "soda-9.0-1";
    url = "https://github.com/bottlesdevs/wine/releases/download/soda-9.0-1/soda-9.0-1-x86_64.tar.xz";
    hash = "sha256-DTa36L7abrduqg3BmD/I/uSddgaVfN87qtCgt+0tKqM=";
    runnerName = "soda-nix";
    sourceDir = "soda-9.0-1-x86_64";
  };
  runtimeComponent = mkBottlesComponent (runtimeComponentInfo // {
    pname = "bottles-${runtimeComponentInfo.name}";
    installPath = "runtimes/${runtimeComponentInfo.name}";
  });
  dxvkComponent = mkBottlesComponent (dxvkComponentInfo // {
    pname = "bottles-${dxvkComponentInfo.name}";
    installPath = "dxvk/${dxvkComponentInfo.name}";
  });
  vkd3dComponent = mkBottlesComponent (vkd3dComponentInfo // {
    pname = "bottles-${vkd3dComponentInfo.name}";
    installPath = "vkd3d/${vkd3dComponentInfo.name}";
  });
  nvapiComponent = mkBottlesComponent (nvapiComponentInfo // {
    pname = "bottles-${nvapiComponentInfo.name}";
    installPath = "nvapi/${nvapiComponentInfo.name}";
  });
  latencyflexComponent = mkBottlesComponent (latencyflexComponentInfo // {
    pname = "bottles-${latencyflexComponentInfo.name}";
    installPath = "latencyflex/${latencyflexComponentInfo.name}";
  });
  caffeRunner = mkBottlesRunner ({
    pname = caffeRunnerInfo.name;
  } // caffeRunnerInfo);
  sodaRunner = mkBottlesRunner ({
    pname = sodaRunnerInfo.name;
  } // sodaRunnerInfo);
in
{
  options = {
    bottles = {
      enable = lib.mkEnableOption "Enable Bottles in home-manager";
    };
  };
  config = lib.mkIf cfg.enable {
    home-manager.users.${username} =
      { config, pkgs, ... }:
      {
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
            categories = [ "Utility" ];
          };
          mimeApps.defaultApplications."x-scheme-handler/bottles" = [
            "com.usebottles.bottles.desktop"
          ];
        };
      };
  };
}
