{inputs, ...}: {
  flake.modules.nixos.base = {
    lib,
    config,
    pkgs,
    ...
  }: let
    cfg = config.local.gaming.gamescope;
  in {
    options = {
      local.gaming.gamescope = {
        enable = lib.mkEnableOption "Enable gamescope in NixOS & home-manager";
      };
    };
    config = lib.mkIf cfg.enable {
      programs.gamescope = {
        enable = true;
        package = inputs.nix-packages.packages.${pkgs.stdenv.hostPlatform.system}.gamescope-patched;
        capSysNice = false; # 'true' breaks gamescope for Steam https://github.com/NixOS/nixpkgs/issues/292620#issuecomment-2143529075
      };
    };
  };
}
