{inputs, ...}: {
  flake.modules.nixos.noctalia-greeter = {
    lib,
    pkgs,
    config,
    ...
  }: {
    imports = [
      inputs.noctalia-greeter.nixosModules.default
    ];

    config = {
      services.displayManager.sddm.enable = lib.mkForce false;

      services.displayManager.noctalia-greeter = {
        enable = true;
        passwordless-sync-users = [config.local.user.name];
        settings = {
          cursor = {
            theme = "Bibata-Modern-Ice";
            size = 22;
            path = "${pkgs.bibata-cursors}/share/icons";
          };
          keyboard.layout = "us";
        };
      };

      environment.systemPackages = [pkgs.bibata-cursors];
    };
  };
}
