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
