{
  lib,
  inputs,
  username,
  ...
}: {
  imports = [
    inputs.dms.nixosModules.greeter
  ];

  services.displayManager.sddm.enable = lib.mkForce false;

  programs.dank-material-shell.greeter = {
    enable = true;
    compositor.name = "niri";
    configHome = "/home/${username}";
  };
}
