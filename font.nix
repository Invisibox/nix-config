{
  pkgs,
  inputs,
  ...
}: {
  fonts = {
    enableDefaultPackages = true;
    fontDir.enable = true;
    fontconfig = {
      enable = true;
      defaultFonts = {
        sansSerif = [
          "Sarasa Gothic SC"
          "Noto Sans CJK SC"
          "Noto Sans"
          "DejaVu Sans"
        ];
        serif = [
          "Noto Serif CJK SC"
          "Noto Serif"
          "DejaVu Serif"
        ];
        monospace = [
          "FiraCode Nerd Font"
          "Sarasa Mono SC"
          "Noto Sans Mono CJK SC"
          "Noto Sans Mono"
        ];
        emoji = ["Noto Color Emoji"];
      };

      localConf = ''
        <?xml version="1.0"?>
        <!DOCTYPE fontconfig SYSTEM "fonts.dtd">
        <fontconfig>
          <alias binding="strong">
            <family>sans-serif</family>
            <prefer>
              <family>Sarasa Gothic SC</family>
              <family>Noto Sans CJK SC</family>
              <family>Noto Sans</family>
              <family>DejaVu Sans</family>
            </prefer>
          </alias>

          <alias binding="strong">
            <family>serif</family>
            <prefer>
              <family>Noto Serif CJK SC</family>
              <family>Noto Serif</family>
              <family>DejaVu Serif</family>
            </prefer>
          </alias>

          <alias binding="strong">
            <family>monospace</family>
            <prefer>
              <family>FiraCode Nerd Font</family>
              <family>Sarasa Mono SC</family>
              <family>Noto Sans Mono CJK SC</family>
              <family>Noto Sans Mono</family>
            </prefer>
          </alias>

          <match target="pattern">
            <test name="lang" compare="contains">
              <string>zh</string>
            </test>
            <test qual="any" name="family">
              <string>sans-serif</string>
            </test>
            <edit name="family" mode="prepend">
              <string>Sarasa Gothic SC</string>
            </edit>
          </match>

          <match target="pattern">
            <test name="lang" compare="contains">
              <string>zh</string>
            </test>
            <test qual="any" name="family">
              <string>serif</string>
            </test>
            <edit name="family" mode="prepend">
              <string>Noto Serif CJK SC</string>
            </edit>
          </match>

          <match target="pattern">
            <test name="lang" compare="contains">
              <string>zh</string>
            </test>
            <test qual="any" name="family">
              <string>monospace</string>
            </test>
            <edit name="family" mode="prepend">
              <string>Sarasa Mono SC</string>
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
      noto-fonts-cjk-serif
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
