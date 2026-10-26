{config, ...}: {
  flake.modules.nixos.services = {
    imports = [config.flake.modules.nixos.dae];

    services.tailscale.enable = true;
  };
}
