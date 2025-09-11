{
  lib,
  config,
  pkgs,
  username,
  ...
}:
let
  cfg = config.virtualization;
in
{
  options = {
    virtualization = {
      enable = lib.mkEnableOption "Enable containerization (Podman) in NixOS & home-manager";
    };
  };
  config = lib.mkIf cfg.enable {
    # --- boot 部分 ---
    boot.kernel.sysctl = {
      "net.ipv4.ip_forward" = 1;
    };
    # --- environment.systemPackages 部分 ---
    environment.systemPackages = with pkgs; [
      docker-compose # Podman 可以使用 docker-compose 文件
      podlet         # 用于从 Podman 容器生成 systemd 服务
      podman-desktop
    ];
    # --- virtualisation.podman 部分 ---
    virtualisation.podman = {
      enable = true;
      autoPrune = {
        enable = true;
        dates = "weekly";
      };
      defaultNetwork.settings.dns_enabled = true;
      # 保持与 Docker 的兼容性，这样 docker-compose 才能工作
      dockerCompat = true;
    };
    users.users.${username} = {
      extraGroups = [
        "docker" # 为了 dockerCompat socket
        "podman"
      ];
    };
    home-manager.users.${username} = { };
  };
}