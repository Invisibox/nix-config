{inputs, ...}: {
  imports = [
    inputs.noctalia.homeModules.default
  ];

  programs.noctalia = {
    enable = true;
    systemd.enable = true;

    # Let Niri reserve the bar gap so window shadows can render behind the
    # transparent layer surface instead of stopping at its exclusive zone.
    settings.bar.default.reserve_space = false;
  };
}
