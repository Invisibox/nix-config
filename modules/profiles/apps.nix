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
      inputs.nix-flatpak.nixosModules.nix-flatpak
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

    services.flatpak = {
      enable = true;
      update.onActivation = true;
      packages = [
        {appId = "com.baidu.NetDisk";}
        {appId = "com.tencent.WeChat";}
        {appId = "com.qq.QQ";}
        {appId = "com.tencent.wemeet";}
        {appId = "com.openwebui.open-webui";}
      ];
    };
  };
}
