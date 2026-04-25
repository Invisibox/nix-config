{
  description = "A simple NixOS flake";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";

    nixpkgs-stable.url = "github:NixOS/nixpkgs/nixos-25.05";

    flake-parts.url = "github:hercules-ci/flake-parts";
    systems.url = "github:nix-systems/default";

    nix-flatpak.url = "github:gmodena/nix-flatpak/?ref=latest";

    zen-browser = {
      url = "github:0xc000022070/zen-browser-flake";
      # IMPORTANT: we're using "libgbm" and is only available in unstable so ensure
      # to have it up-to-date or simply don't specify the nixpkgs input
      inputs.nixpkgs.follows = "nixpkgs";
      inputs.home-manager.follows = "home-manager";
    };

    chinese-fonts-overlay = {
      url = "github:brsvh/chinese-fonts-overlay";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    steam-config-nix = {
      url = "github:different-name/steam-config-nix";
      inputs.nixpkgs.follows = "nixpkgs";
      inputs.flake-parts.follows = "flake-parts";
      inputs.systems.follows = "systems";
    };

    niri-unstable = {
      url = "github:niri-wm/niri?ref=main";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    dms = {
      url = "github:AvengeMedia/DankMaterialShell/stable";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    daeuniverse = {
      url = "github:daeuniverse/flake.nix";
      inputs.nixpkgs.follows = "nixpkgs";
      inputs.flake-parts.follows = "flake-parts";
    };

    spicetify-nix = {
      url = "github:Gerg-L/spicetify-nix";
      inputs.nixpkgs.follows = "nixpkgs";
      inputs.systems.follows = "systems";
    };
  };

  outputs = {
    self,
    nixpkgs,
    nix-flatpak,
    # stylix,
    home-manager,
    ...
  } @ inputs: {
    nixosConfigurations.ASUS = nixpkgs.lib.nixosSystem {
      system = "x86_64-linux";
      specialArgs = {
        inherit inputs;
        username = "zh";
      };
      modules = [
        # 这里导入之前我们使用的 configuration.nix，
        # 这样旧的配置文件仍然能生效
        ./configuration.nix

        # stylix.nixosModules.stylix

        # 将 home-manager 配置为 nixos 的一个 module
        # 这样在 nixos-rebuild switch 时，home-manager 配置也会被自动部署
        home-manager.nixosModules.home-manager
        {
          home-manager.useGlobalPkgs = true;
          home-manager.useUserPackages = true;
          home-manager.users.zh = import ./home-manager/home.nix;

          home-manager.backupFileExtension = "hm-back";

          home-manager.sharedModules = [
            nix-flatpak.homeManagerModules.nix-flatpak
            inputs.spicetify-nix.homeManagerModules.default
            inputs.steam-config-nix.homeModules.default
          ];

          # 使用 home-manager.extraSpecialArgs 自定义传递给 ./home.nix 的参数
          # 取消注释下面这一行，就可以在 home.nix 中使用 flake 的所有 inputs 参数了
          home-manager.extraSpecialArgs = {inherit inputs;};
        }
      ];
    };
  };
}
