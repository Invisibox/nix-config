{ inputs, nixpkgs, self, username, host, ...}:

{
  imports = [
    ./bootloader.nix
    ./hardware.nix
    ./network.nix
    ./pipewire.nix
    ./services.nix
    ./wayland.nix
    ./i18n.nix
  ];
}