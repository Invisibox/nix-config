# Edit this configuration file to define what should be installed on
# your system. Help is available in the configuration.nix(5) man page, on
# https://search.nixos.org/options and in the NixOS manual (`nixos-help`).

{ config, lib, pkgs, inputs, ... }:

{
  imports =
    [ # Include the results of the hardware scan.
      ./hardware-configuration.nix
      ../../modules/default.nix
    ];
  
  networking = {
    hostName = "nixos";
  };

  services.libinput.enable = true;

  environment.systemPackages = with pkgs; [
    vim # Do not forget to add an editor to edit configuration.nix! The Nano editor is also installed by default.
    wget
    curl
    git
    neovim
    alsa-utils
    gnupg
  ];

  fonts = {
    packages = with pkgs; [
      sarasa-gothic
      noto-fonts-emoji
    ];
    fontconfig = {
      antialias = true;
      hinting.enable = true;
    };
  };

  users.users.admin = {
    isNormalUser = true;
    description = "admin";
    extraGroups = [ "networkmanager" "wheel" ];
    packages = with pkgs; [
      firefox
    #  thunderbird
    ];
  };

  hardware.graphics.enable = true;

  environment.variables.EDITOR = "neovim";

  system.stateVersion = "24.05"; # Did you read the comment?

}

