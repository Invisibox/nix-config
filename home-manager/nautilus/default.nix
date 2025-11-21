{ pkgs, ... }:

let
  nautEnv = pkgs.buildEnv {
    name = "nautilus-env";

    paths = with pkgs; [
      nautilus
      nautilus-python
      nautilus-open-any-terminal
      code-nautilus
      gnomeExtensions.flickernaut
      gnome.gvfs
      sushi
    ];
  };
in

{
  home = {
    packages = [ nautEnv ];
    sessionVariables.NAUTILUS_4_EXTENSION_DIR = "${nautEnv}/lib/nautilus/extensions-4";
  };

  dconf = {
    enable = true;
    settings."com/github/stunkymonkey/nautilus-open-any-terminal".terminal = "kitty";
  };
}