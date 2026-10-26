{inputs, ...}: {
  flake.modules.nixos.oxide-term = {
    lib,
    config,
    pkgs,
    ...
  }: let
    cfg = config.local.apps.oxide-term;
    localUserName = config.local.user.name;

    oxideTermPackage = inputs.nix-packages.packages.${pkgs.stdenv.hostPlatform.system}.oxideterm;
  in {
    options.local.apps.oxide-term = {
      package = lib.mkOption {
        type = lib.types.package;
        default = oxideTermPackage;
        description = "The OxideTerm package installed for the user.";
      };
    };

    config = {
      home-manager.users.${localUserName} = {
        home = {
          file.".local/bin/oxideterm".source = "${cfg.package}/opt/oxideterm/resources/cli-bin/x86_64-unknown-linux-gnu/oxideterm";

          packages = [
            cfg.package
          ];
        };
      };
    };
  };
}
