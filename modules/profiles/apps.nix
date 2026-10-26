{
  config,
  inputs,
  ...
}: let
  nixosModules = config.flake.modules.nixos;
  homeModule = config.flake.modules.homeManager.apps;
in {
  flake.modules.nixos.apps = {config, ...}: {
    imports = [
      nixosModules.brave-origin
      nixosModules.localsend
      nixosModules.onlyoffice
      nixosModules.oxide-term
      nixosModules.paseo
      nixosModules.obs
      # nixosModules.bottles
      # nixosModules.moonlight
      # nixosModules.waydroid
      # nixosModules.texlive
      # nixosModules.wps
    ];

    home-manager.users.${config.local.user.name}.imports = [homeModule];

    environment.systemPackages = with inputs.nix-packages.packages.${config.nixpkgs.hostPlatform.system}; [
      wechat-jailed
      qq-jailed
      baidunetdisk-jailed
    ];
  };
}
