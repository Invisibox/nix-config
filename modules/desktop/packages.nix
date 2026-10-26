{
  flake.modules.nixos.desktop = {pkgs, ...}: {
    environment.systemPackages = with pkgs; [
      xsettingsd
      xrdb
      xdg-desktop-portal-gtk
      vulkan-tools
      pavucontrol
      dconf-editor
    ];
  };

  flake.modules.homeManager.desktop = {pkgs, ...}: {
    home.packages = with pkgs; [
      ddcutil
      pango
      wl-clipboard
    ];
  };
}
