{inputs, ...}: {
  flake.modules.homeManager.desktop = {pkgs, ...}: let
    nautEnv = inputs.nix-packages.packages.${pkgs.stdenv.hostPlatform.system}.nautilus-with-extensions;
  in {
    home = {
      packages = [nautEnv];
      sessionVariables.NAUTILUS_4_EXTENSION_DIR = "${nautEnv}/lib/nautilus/extensions-4";
    };

    dconf = {
      enable = true;
      settings."com/github/stunkymonkey/nautilus-open-any-terminal".terminal = "kitty";
    };
  };
}
