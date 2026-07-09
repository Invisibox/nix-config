{pkgs, ...}: {
  local.apps.brave-origin.enable = true;
  local.apps.lobehub.enable = true;
  local.apps.cc-switch.enable = true;
  local.apps.localsend.enable = true;
  local.apps.moonlight.enable = true;
  local.apps.netcatty.enable = true;
  local.apps.oxide-term.enable = true;
  local.apps.im.enable = true;
  local.apps.bottles.enable = true;

  local.apps.waydroid = {
    enable = true;
    initSystemType = "GAPPS";
    package = pkgs.waydroid-nftables;
  };

  local.apps.obs = {
    enable = true;
    enableNative = true;
    silenceOutput = true;
  };

  local.apps.texlive.enable = true;
  local.apps.wps.enable = true;
  local.apps.wemeet.enable = true;
}
