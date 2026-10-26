{inputs, ...}: {
  flake.modules.homeManager.desktop = {...}: {
    # Home Manager now ships a built-in Noctalia module at this path. The
    # Noctalia flake provides its own module, so disable the built-in one to
    # avoid declaring programs.noctalia options twice.
    disabledModules = ["programs/noctalia"];

    imports = [
      inputs.noctalia.homeModules.default
    ];

    programs.noctalia = {
      enable = true;
      systemd.enable = true;
    };
  };
}
