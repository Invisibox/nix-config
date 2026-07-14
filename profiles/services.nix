{...}: {
  services.tailscale.enable = true;

  local.services.daed = {
    enable = true;
    dashboardAddress = "127.0.0.1";
    dashboardPort = 2023;
    openDashboardFirewall = false;
    tproxyPort = 12345;
  };
}
