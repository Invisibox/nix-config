{inputs, ...}: {
  flake.modules.nixos.gamescope = {pkgs, ...}: {
    programs.gamescope = {
      enable = true;
      package = inputs.nix-packages.packages.${pkgs.stdenv.hostPlatform.system}.gamescope-patched;
      capSysNice = false; # 'true' breaks gamescope for Steam https://github.com/NixOS/nixpkgs/issues/292620#issuecomment-2143529075
    };
  };
}
