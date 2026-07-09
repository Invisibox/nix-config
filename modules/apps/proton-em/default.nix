{
  lib,
  pkgs,
  ...
}: let
  protonEmPackage = pkgs.callPackage ./package.nix {};
in {
  options.local.gaming.proton-em.package = lib.mkOption {
    type = lib.types.package;
    default = protonEmPackage;
    description = "Proton EM compatibility tool used by Steam, Bottles, and related launchers.";
  };
}
