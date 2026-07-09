{
  lib,
  pkgs,
  inputs,
  config,
  username,
  ...
}: let
  cfg = config.local.desktop.dms-greeter;
  greeterCursorTheme = "Bibata-Modern-Ice";
  greeterCursorSize = 22;
  greeterShowSeconds = true;
  greeterFontFamily = "Inter Variable";
  jq = lib.getExe pkgs.jq;
in {
  imports = [
    inputs.dms.nixosModules.greeter
  ];

  options.local.desktop.dms-greeter = {
    enable = lib.mkEnableOption "Enable Dank Material Shell greeter";
  };

  config = lib.mkIf cfg.enable {
    services.displayManager.sddm.enable = lib.mkForce false;

    programs.dank-material-shell.greeter = {
      enable = true;
      compositor = {
        name = "niri";
        customConfig = ''
          hotkey-overlay {
            skip-at-startup
          }

          environment {
            DMS_RUN_GREETER "1"
          }

          gestures {
            hot-corners {
              off
            }
          }

          layout {
            background-color "#000000"
          }

          cursor {
            xcursor-theme "${greeterCursorTheme}"
            xcursor-size ${toString greeterCursorSize}
          }
        '';
      };
      configHome = "/home/${username}";
    };

    environment.systemPackages = [
      pkgs.bibata-cursors
    ];

    systemd.services.greetd.environment = {
      XCURSOR_THEME = greeterCursorTheme;
      XCURSOR_SIZE = toString greeterCursorSize;
      XCURSOR_PATH = "${pkgs.bibata-cursors}/share/icons:/run/current-system/sw/share/icons";
    };

    # Keep user settings intact: only patch greeter cache copy.
    systemd.services.greetd.preStart = lib.mkAfter ''
      cd /var/lib/dms-greeter

      if [ -f settings.json ]; then
        ${jq} --arg greeterFontFamily "${greeterFontFamily}" \
          '.greeterShowSeconds = ${
        if greeterShowSeconds
        then "true"
        else "false"
      } | .greeterFontFamily = $greeterFontFamily' \
          settings.json > settings.tmp
        mv settings.tmp settings.json
      else
        ${jq} -n --arg greeterFontFamily "${greeterFontFamily}" \
          '{"greeterShowSeconds": ${
        if greeterShowSeconds
        then "true"
        else "false"
      }, "greeterFontFamily": $greeterFontFamily}' \
          > settings.json
      fi
    '';
  };
}
