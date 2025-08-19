{
  pkgs,
  inputs,
  ...
}: {
  nixpkgs.overlays = [
    inputs.chinese-fonts-overlay.overlays.default
  ];

  fonts.packages = with pkgs; [
    noto-fonts
    noto-fonts-cjk-sans
    noto-fonts-emoji
    noto-fonts-color-emoji
    liberation_ttf
    nerd-fonts.jetbrains-mono
    sarasa-gothic
    lxgw-wenkai
    windows-fonts
    inputs.wpsFonts.packages.${system}.default
  ];

  fonts.fontconfig.localConf = ''
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

      <alias>
        <family>sans-serif</family>
        <prefer>
          <family>Noto Sans CJK SC</family>
          <family>Noto Sans CJK TC</family>
          <family>Noto Sans CJK JP</family>
        </prefer>
      </alias>

      <alias>
        <family>serif</family>
        <prefer>
          <family>Noto Serif CJK SC</family>
          <family>Noto Serif CJK TC</family>
          <family>Noto Serif CJK JP</family>
        </prefer>
      </alias>

      <alias>
        <family>monospace</family>
        <prefer>
          <family>Noto Sans Mono CJK SC</family>
          <family>Noto Sans Mono CJK TC</family>
          <family>Noto Sans Mono CJK JP</family>
        </prefer>
      </alias>
    </fontconfig>

  '';
}
