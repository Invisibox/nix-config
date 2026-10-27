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

  flake.modules.homeManager.apps = {pkgs, ...}: {
    home.packages = with pkgs; [
      # terminal emulators and remote connections
      ghostty
      termius

      # networking, downloads, and browsers
      motrix
      qbittorrent-enhanced
      resilio-sync
      # servo
      tor-browser
      v2rayn

      # communication and news readers
      _64gram
      discord
      element-desktop
      # fluffychat
      # fluent-reader
      # keyguard
      newsflash
      thunderbird

      # knowledge management and productivity
      anki
      # calibre
      folio
      # mangayomi
      obsidian
      papers
      planify
      # readest
      typst
      # zotero

      # media and images
      amberol
      # curtail
      piliplus
      qimgv
      tsukimi

      # desktop and system tools
      file-roller
      galaxy-buds-client
      gnome-calculator
      # hmcl
      resources
      # vial
      # winboat
      winbox
    ];
  };
}
