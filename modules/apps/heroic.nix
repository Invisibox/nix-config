{inputs, ...}: {
  flake.modules.nixos.heroic = {
    config,
    pkgs,
    ...
  }: let
    localUserName = config.local.user.name;
    protonGePackage = pkgs.proton-ge-bin.overrideAttrs (_: {
      steamDisplayName = "Proton GE";
    });
    protonCachyos = inputs.chaotic.packages.${pkgs.stdenv.hostPlatform.system}.proton-cachyos_x86_64_v3;
  in {
    home-manager.users.${localUserName} = {config, ...}: {
      home.file = {
        wine-links-proton-cachyos-heroic = {
          source = protonCachyos;
          target = "${config.xdg.configHome}/heroic/tools/proton/proton-cachyos";
        };
        wine-links-proton-ge-heroic = {
          source = "${protonGePackage.steamcompattool}";
          target = "${config.xdg.configHome}/heroic/tools/proton/proton-ge-nix";
        };
      };
      home.packages = [pkgs.heroic];
    };
  };
}
