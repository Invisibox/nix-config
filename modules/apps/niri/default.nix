{
  pkgs,
  lib,
  inputs,
  username,
  ...
}: {
  # Enable Niri
  programs.niri = {
    enable = true;
    # package = pkgs.niri;
    package = inputs.niri-blurry.packages.${pkgs.system}.niri;
  };

  environment.systemPackages = with pkgs; [
    xwayland-satellite
    # material-symbols
    # inter
    # fira-code
  ];

  systemd.user.services.niri-flake-polkit.enable = false;

  services.displayManager.defaultSession = lib.mkForce "niri";

  # home-manager.users.${username} = {
  #   imports = [
  #     ./settings.nix
  #     ./binds.nix
  #   ];
  # };
}
