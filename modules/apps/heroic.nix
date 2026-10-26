{
  flake.modules.nixos.heroic = {
    config,
    pkgs,
    ...
  }: let
    localUserName = config.local.user.name;
    protonPackages = import ./_proton.nix {inherit pkgs;};
    inherit (protonPackages) protonGePackage protonCachyos;
  in {
    home-manager.users.${localUserName} = {config, ...}: {
      home.file = {
        wine-links-proton-cachyos-heroic = {
          source = "${protonCachyos}/share/steam/compatibilitytools.d/proton-cachyos";
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
