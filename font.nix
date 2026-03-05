{pkgs, ...}: {
  fonts = {
    enableDefaultPackages = true;
    fontDir.enable = true;
    fontconfig = {
      enable = true;
      defaultFonts = {
        sansSerif = [
          "Sarasa Gothic SC"
          "Noto Sans"
          "DejaVu Sans"
        ];
        serif = [
          "LXGW WenKai"
          "Noto Serif"
          "DejaVu Serif"
        ];
        monospace = [
          "FiraCode Nerd Font"
          "Sarasa Mono SC"
          "Noto Sans Mono"
        ];
        emoji = ["Noto Color Emoji"];
      };

      localConf = ''
        <?xml version="1.0"?>
        <!DOCTYPE fontconfig SYSTEM "fonts.dtd">
        <fontconfig>
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
