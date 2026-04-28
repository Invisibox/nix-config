{
  lib,
  pkgs,
  inputs,
  username,
  ...
}: let
  greeterCursorTheme = "Bibata-Modern-Ice";
  greeterCursorSize = 22;
  greeterShowSeconds = true;
  greeterFontFamily = "Inter Variable";
  jq = lib.getExe pkgs.jq;
in {
  imports = [
    inputs.dms.nixosModules.greeter
  ];

  services.displayManager.sddm.enable = lib.mkForce false;

  programs.dank-material-shell.greeter = {
    enable = true;
    compositor.name = "niri";
    configHome = "/home/${username}";
  };

  # dms-greeter's niri launcher auto-includes this file when present.
  environment.etc."greetd/niri_overrides.kdl".text = ''
    cursor {
      xcursor-theme "${greeterCursorTheme}"
      xcursor-size ${toString greeterCursorSize}
    }
  '';

  # Keep user settings intact: only patch greeter cache copy.
  systemd.services.greetd.preStart = lib.mkAfter ''
    cd /var/lib/dms-greeter

    if [ -f settings.json ]; then
      ${jq} --arg greeterFontFamily "${greeterFontFamily}" \
        '.greeterShowSeconds = ${if greeterShowSeconds then "true" else "false"} | .greeterFontFamily = $greeterFontFamily' \
        settings.json > settings.tmp
      mv settings.tmp settings.json
    else
      ${jq} -n --arg greeterFontFamily "${greeterFontFamily}" \
        '{"greeterShowSeconds": ${if greeterShowSeconds then "true" else "false"}, "greeterFontFamily": $greeterFontFamily}' \
        > settings.json
    fi
  '';
}
