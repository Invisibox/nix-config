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
    material-symbols
    inter
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
    </fontconfig>

  '';
}
