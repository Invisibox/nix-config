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
      nixosModules.wps
      nixosModules.oxide-term
      nixosModules.paseo
      nixosModules.obs
      nixosModules.bottles
      # nixosModules.waydroid
      # nixosModules.texlive
      # nixosModules.onlyoffice
    ];

    home-manager.users.${config.local.user.name}.imports = [homeModule];

    environment.systemPackages = with inputs.nix-packages.packages.${config.nixpkgs.hostPlatform.system}; [
      baidupcs-rust
    ];
  };

  flake.modules.homeManager.apps = {pkgs, ...}: let
    packages = inputs.nix-packages.packages.${pkgs.stdenv.hostPlatform.system};
  in {
    home.packages = with pkgs; [
      # terminal emulators and remote connections
      ghostty
      termius

      # networking, downloads, and browsers
      motrix
      nextcloud-client
      qbittorrent-enhanced
      resilio-sync
      # servo
      tor-browser
      v2rayn

      # communication and news readers
      packages.wechat-jailed
      packages.qq-jailed
      _64gram
      discord
      # fluffychat
      # fluent-reader
      packages.godwit
      # keyguard
      # newsflash
      packages.sable-next
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
      packages.pilinara
      qimgv
      rufin
      # tsukimi

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
