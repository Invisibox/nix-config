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
      ${jq} '.greeterShowSeconds = ${if greeterShowSeconds then "true" else "false"}' settings.json > settings.tmp
      mv settings.tmp settings.json
    else
      ${jq} -n '{"greeterShowSeconds": ${if greeterShowSeconds then "true" else "false"}}' > settings.json
    fi
  '';
}
