{pkgs, ...}: let
  nautilusWithGst = pkgs.nautilus.overrideAttrs (nprev: {
    buildInputs =
      (nprev.buildInputs or [])
      ++ [
        pkgs.gst_all_1.gst-plugins-good
        pkgs.gst_all_1.gst-plugins-bad
      ];
  });

  nautEnv = pkgs.buildEnv {
    name = "nautilus-env";

    paths = [
      nautilusWithGst
      pkgs.nautilus-python
      pkgs.nautilus-open-any-terminal
      pkgs.code-nautilus
      pkgs.gnomeExtensions.flickernaut
      pkgs.gnome.gvfs
      pkgs.sushi
    ];
  };
in {
  home = {
    packages = [nautEnv];
    sessionVariables.NAUTILUS_4_EXTENSION_DIR = "${nautEnv}/lib/nautilus/extensions-4";
  };

  dconf = {
    enable = true;
    settings."com/github/stunkymonkey/nautilus-open-any-terminal".terminal = "kitty";
  };
}
