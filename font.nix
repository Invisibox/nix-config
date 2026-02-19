{pkgs, ...}: {
  fonts = {
    fontDir.enable = true;
    fontconfig = {
      enable = true;
      # 1. 关键：设置默认字体优先级
      defaultFonts = {
        # 无衬线字体：网页和 UI 最常用的字体
        sansSerif = [
          "Sarasa Gothic SC" # 更纱黑体 简体中文
          "Sarasa Gothic TC" # 更纱黑体 繁体（台湾）
          "Sarasa Gothic J" # 更纱黑体 日文
          "Sarasa Gothic K" # 更纱黑体 韩文
          "Noto Sans CJK SC" # 备选
        ];
        # 衬线字体：你装了霞鹜文楷，它的观感非常接近衬线，可以放这里
        serif = [
          "LXGW WenKai"
          "Noto Serif CJK SC"
        ];
        # 等宽字体：代码编辑器的灵魂
        monospace = [
          "JetBrainsMono Nerd Font" # 你的 JetBrainsMono
          "Sarasa Mono SC" # 更纱等宽 简体中文
          "Sarasa Mono J" # 更纱等宽 日文变体
        ];
        emoji = ["Noto Color Emoji"];
      };

      # 你原有的 Emoji 配置
      localConf = ''
        <?xml version="1.0"?>
        <!DOCTYPE fontconfig SYSTEM "fonts.dtd">
        <fontconfig>
          <match target="pattern">
            <test name="lang">
              <string>zh-cn</string>
            </test>
            <test name="family">
              <string>sans-serif</string>
            </test>
            <edit name="family" mode="prepend" binding="strong">
              <string>Sarasa Gothic SC</string>
            </edit>
          </match>
          <match target="pattern">
            <test name="lang">
              <string>zh-tw</string>
            </test>
            <test name="family">
              <string>sans-serif</string>
            </test>
            <edit name="family" mode="prepend" binding="strong">
              <string>Sarasa Gothic TC</string>
            </edit>
          </match>
          <match target="pattern">
            <test name="lang">
              <string>ja</string>
            </test>
            <test name="family">
              <string>sans-serif</string>
            </test>
            <edit name="family" mode="prepend" binding="strong">
              <string>Sarasa Gothic J</string>
            </edit>
          </match>
          <match target="pattern">
            <test name="pattern">
              <string>ko</string>
            </test>
            <test name="family">
              <string>sans-serif</string>
            </test>
            <edit name="family" mode="prepend" binding="strong">
              <string>Sarasa Gothic K</string>
            </edit>
          </match>
          <match target="font">
            <test name="family" qual="first">
              <string>Noto Color Emoji</string>
            </test>
            <edit name="antialias" mode="assign">
              <bool>false</bool>
            </edit>
          </match>
        </fontconfig>
      '';
    };

    packages = with pkgs; [
      noto-fonts
      noto-fonts-cjk-sans
      noto-fonts-color-emoji
      liberation_ttf
      material-symbols
      inter
      nerd-fonts.jetbrains-mono
      nerd-fonts.fira-code
      sarasa-gothic
      lxgw-wenkai
    ];
  };
}
