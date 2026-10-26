{
  flake.modules.nixos.services = {...}: {
    services.tailscale.enable = true;

    local.services.dae.enable = true;
  };
}
