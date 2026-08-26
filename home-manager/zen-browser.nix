{inputs, ...}: {
  imports = [inputs.zen-browser.homeModules.beta];

  programs.zen-browser = {
    enable = true;

    profiles.default = {
      settings."zen.widget.linux.transparency" = true;
    };
  };
}
