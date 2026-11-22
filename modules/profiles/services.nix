{config, ...}: {
  flake.modules.nixos.services = {
    imports = [config.flake.modules.nixos.honk];

    services.tailscale.enable = true;
  };
}
