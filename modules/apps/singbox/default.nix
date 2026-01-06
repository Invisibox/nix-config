{ config, pkgs, lib, ... }: # <--- 1. 确保这里引入了 lib

{
  # 2. 安装 gui-for-singbox (如果想试用 Hiddify，把下面的包换成 hiddify 即可)
  environment.systemPackages = with pkgs; [
    sing-box 
  ];

  # 3. 权限设置
  # GUI 软件修改网卡需要申请 root 权限，必须开启 Polkit
  security.polkit.enable = true;

  # 4. 网络与内核设置 (修复了冲突错误)
  boot.kernel.sysctl = {
    # 使用 lib.mkDefault 避免与 virtualization 模块冲突
    # 这样如果你的虚拟化模块已经开了转发，就不会报错；
    # 如果你关了虚拟化，这里依然能保证 singbox 可用。
    "net.ipv4.ip_forward" = lib.mkDefault 1;
    "net.ipv6.conf.all.forwarding" = lib.mkDefault 1;
  };

  networking.firewall = {
    # (A) 信任 TUN 接口
    # 这一步很关键，否则流量回来会被挡住
    # gui-for-singbox 默认可能会用 singbox-tun 或 tun0，建议都写上
    trustedInterfaces = [ "tun0" "singbox-tun" ];

    # (B) 宽松的反向路径检查
    # NixOS 默认 strict 会丢弃透明代理的包，必须设为 loose
    checkReversePath = "loose";
    
    # (C) 允许 UDP 用于 DNS 和 QUIC
    allowedUDPPorts = [ 53 443 ];
  };
}
