{inputs, ...}: {
  flake.modules.nixos.bottles = {
    config,
    pkgs,
    ...
  }: let
    localUserName = config.local.user.name;
    protonCachyos = inputs.chaotic.packages.${pkgs.stdenv.hostPlatform.system}.proton-cachyos_x86_64_v3;
    bottlesPackage = inputs.nix-packages.packages.${pkgs.stdenv.hostPlatform.system}.bottles;
    inherit
      (bottlesPackage)
      protonGePackage
      winebridge
      runtimeComponent
      dxvkComponent
      vkd3dComponent
      nvapiComponent
      latencyflexComponent
      caffeRunner
      sodaRunner
      runtimeComponentInfo
      dxvkComponentInfo
      vkd3dComponentInfo
      nvapiComponentInfo
      latencyflexComponentInfo
      ;
  in {
    config = {
      home-manager.users.${localUserName} = {
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
            proton-links-proton-ge-bottles = {
              source = protonGePackage.steamcompattool;
              target = "${config.xdg.dataHome}/bottles/runners/proton-ge-nix";
            };
            proton-links-proton-cachyos-bottles = {
              source = protonCachyos;
              target = "${config.xdg.dataHome}/bottles/runners/proton-cachyos-nix";
            };
          };
          packages = [
            bottlesPackage
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
  };
}
