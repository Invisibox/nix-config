{
  inputs,
  pkgs,
  ...
}: let
  zenBrowserSources = builtins.fromJSON (builtins.readFile "${inputs.zen-browser}/sources.json");
  betterfoxSource = pkgs.fetchFromGitHub {
    inherit (zenBrowserSources.addons.betterfox) rev hash;
    owner = "yokoffing";
    repo = "Betterfox";
  };
in {
  imports = [inputs.zen-browser.homeModules.beta];

  programs.zen-browser = {
    enable = true;
    setAsDefaultBrowser = true;

    profiles.default = {
      settings."zen.widget.linux.transparency" = true;

      search = {
        force = true;
        default = "kagi";
        privateDefault = "ddg";

        engines = {
          mynixos = {
            name = "My NixOS";
            urls = [
              {
                template = "https://mynixos.com/search?q={searchTerms}";
                params = [
                  {
                    name = "query";
                    value = "searchTerms";
                  }
                ];
              }
            ];
            icon = "${pkgs.nixos-icons}/share/icons/hicolor/scalable/apps/nix-snowflake.svg";
            definedAliases = ["@nx"];
          };

          github = {
            name = "GitHub Search";
            urls = [
              {
                template = "https://github.com/search?q={searchTerms}";
              }
            ];
            definedAliases = ["@gh"];
          };

          kagi = {
            name = "Kagi";
            urls = [
              {
                template = "https://kagi.com/search?q={searchTerms}";
              }
            ];
            definedAliases = ["@kagi"];
          };
        };
      };

      extraConfig = ''
        ${builtins.readFile "${betterfoxSource}/user.js"}
        ${builtins.readFile "${betterfoxSource}/Securefox.js"}
        ${builtins.readFile "${betterfoxSource}/Peskyfox.js"}

        /****************************************************************************
         * Smoothfox: NATURAL SMOOTH SCROLLING V3 [MODIFIED]                       *
         ****************************************************************************/
        user_pref("apz.overscroll.enabled", true);
        user_pref("general.smoothScroll", true);
        user_pref("general.smoothScroll.msdPhysics.continuousMotionMaxDeltaMS", 12);
        user_pref("general.smoothScroll.msdPhysics.enabled", true);
        user_pref("general.smoothScroll.msdPhysics.motionBeginSpringConstant", 600);
        user_pref("general.smoothScroll.msdPhysics.regularSpringConstant", 650);
        user_pref("general.smoothScroll.msdPhysics.slowdownMinDeltaMS", 25);
        user_pref("general.smoothScroll.msdPhysics.slowdownMinDeltaRatio", "2");
        user_pref("general.smoothScroll.msdPhysics.slowdownSpringConstant", 250);
        user_pref("general.smoothScroll.currentVelocityWeighting", "1");
        user_pref("general.smoothScroll.stopDecelerationWeighting", "1");
        user_pref("mousewheel.default.delta_multiplier_y", 300);
      '';
    };
  };
}
