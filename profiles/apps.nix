{pkgs, ...}: {
  local.apps.brave-origin.enable = true;
  local.apps.lobehub.enable = true;
  local.apps.localsend.enable = true;
  # local.apps.moonlight.enable = true;
  local.apps.oxide-term.enable = true;
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
  services.flatpak = {
    enable = true;
    update.onActivation = true;
    packages = [
      {appId = "com.baidu.NetDisk";}
      {appId = "com.tencent.WeChat";}
      {appId = "com.qq.QQ";}
      {appId = "com.tencent.wemeet";}
    ];
  };
}
