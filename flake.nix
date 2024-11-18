{
  description = "A very basic flake";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs?ref=nixos-unstable";
    ayugram-desktop.url = "github:/ayugram-port/ayugram-desktop/release?submodules=1";
#     hardware.url = "github:nixos/nixos-hardware";
  };

  outputs = { self, nixpkgs, ayugram-desktop, ... }@inputs: {
    nixosConfigurations.nixos = nixpkgs.lib.nixosSystem {
      system = "x86_64-linux";
      modules = [
        # 这里导入之前我们使用的 configuration.nix，
        # 这样旧的配置文件仍然能生效
        ./configuration.nix
        { _module.args = { inherit inputs; };}
        {
            # given the users in this list the right to specify additional substituters via:
            #    1. `nixConfig.substituters` in `flake.nix`
            nix.settings.trusted-users = [ "zh" ];
        }
      ];
    };
  };
}
