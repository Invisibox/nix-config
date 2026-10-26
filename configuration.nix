{
  config,
  inputs,
  ...
}: {
  flake.nixosConfigurations.thinkpad-t14s = inputs.nixpkgs.lib.nixosSystem {
    system = "x86_64-linux";
    modules = [config.flake.modules.nixos.thinkpad-t14s];
  };
}
