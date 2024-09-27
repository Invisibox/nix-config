{
  description = "A simple NixOS flake";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    #nixos-hardware.url = "github:NixOS/nixos-hardware/master";
    #ayugram-desktop.url = "github:kaeeraa/ayugram-desktop/release?submodules=1";
  };

  outputs = { self, nixpkgs, ... }@inputs: {
    nixosConfigurations.nixos = nixpkgs.lib.nixosSystem {
      system = "x86_64-linux";
      modules = [
        ./configuration.nix
        #nixos-hardware.nixosModules.asus-battery
        {_module.args = { inherit inputs; };}
      ];
    };
  };
}
