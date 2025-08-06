{
  config,
  pkgs,
  ...
}: {
nixpkgs.overlays = [
    (self: super: {
      # 我们要覆盖 'wps-office-cn' 这个包
      wps-office-cn = super.wps-office-cn.overrideAttrs (oldAttrs: {
        # 我们使用 postInstall 钩子, 在包安装完成后执行额外操作
        postInstall = ''
          # wrapProgram 是一个Nix提供的便利工具
          # 它会为指定程序创建一个包装脚本
          # --set <VAR> <VALUE> 会在脚本中设置环境变量

          # 为WPS文字 (wps) 创建包装
          wrapProgram $out/bin/wps --set QT_IM_MODULE fcitx5

          # 为WPS演示 (wpp) 创建包装
          wrapProgram $out/bin/wpp --set QT_IM_MODULE fcitx5

          # 为WPS表格 (et) 创建包装
          wrapProgram $out/bin/et --set QT_IM_MODULE fcitx5
        '';
      });
    })
  ];
}
