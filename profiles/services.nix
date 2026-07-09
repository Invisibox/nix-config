{
  lib,
  pkgs,
  ...
}: {
  services.tailscale.enable = true;

  services.postgresql = {
    enable = true;
    package = pkgs.postgresql_16;
  };
  # 禁用开机自启
  systemd.services.postgresql.wantedBy = lib.mkForce [];

  local.services.daed = {
    enable = true;
    dashboardAddress = "127.0.0.1";
    dashboardPort = 2023;
    openDashboardFirewall = false;
    tproxyPort = 12345;
  };
}
