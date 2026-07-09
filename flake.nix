{
  description = "A simple NixOS flake";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";

    nixpkgs-stable.url = "github:NixOS/nixpkgs/nixos-26.05";

    niri-flake.url = "github:sodiboo/niri-flake";

    flake-parts.url = "github:hercules-ci/flake-parts";
    systems.url = "github:nix-systems/default";

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
    # stylix,
    home-manager,
    ...
  } @ inputs: let
    system = "x86_64-linux";
  in {
    formatter.${system} = nixpkgs.legacyPackages.${system}.alejandra;

    nixosConfigurations.ASUS = nixpkgs.lib.nixosSystem {
      inherit system;
      specialArgs = {
        inherit inputs;
      };
      modules = [
        ./hosts/ASUS

        # stylix.nixosModules.stylix

        # 将 home-manager 配置为 nixos 的一个 module
        # 这样在 nixos-rebuild switch 时，home-manager 配置也会被自动部署
        home-manager.nixosModules.home-manager
        ({config, ...}: let
          localUserName = config.local.user.name;
          localUserHome = config.local.user.home;
        in {
          home-manager.useGlobalPkgs = true;
          home-manager.useUserPackages = true;
          home-manager.users.${localUserName} = {
            imports = [./home-manager/home.nix];
            home = {
              username = localUserName;
              homeDirectory = localUserHome;
            };
          };

          home-manager.backupFileExtension = "hm-back";

          home-manager.sharedModules = [
            inputs.spicetify-nix.homeManagerModules.default
            inputs.steam-config-nix.homeModules.default
          ];

          # Home Manager modules still consume flake inputs directly.
          home-manager.extraSpecialArgs = {inherit inputs;};
        })
      ];
    };
  };
}
