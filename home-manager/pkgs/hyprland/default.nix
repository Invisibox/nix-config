{ inputs, ... }: 
{
  imports = [
    inputs.hyprland.homeManagerModules.default
    ./hyprland.nix
    ./config.nix
    ./hyprlock.nix
    ./variables.nix
  ];
}
