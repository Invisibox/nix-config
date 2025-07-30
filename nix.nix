{
  config,
  pkgs,
  inputs,
  ...
}: {
  # Allow unfree packages
  nixpkgs.config.allowUnfree = true;

  # do garbage collection weekly to keep disk usage low
  nix = {
    gc = {
      automatic = true;
      dates = "weekly";
      options = "--delete-older-than 1w";
    };

    optimise = {
      automatic = true;
      dates = ["1w"];
    };

    settings = {
      warn-dirty = false;
      experimental-features = [
        "nix-command"
        "flakes"
        "pipe-operators"
      ];
      builders-use-substitutes = true;
      auto-optimise-store = true;
      trusted-users = [
        "root"
        "zh"
        "@wheel"
      ];

      substituters = [
        # cache mirror located in China
        # status: https://mirrors.ustc.edu.cn/status/
        "https://mirrors.ustc.edu.cn/nix-channels/store"
        # status: https://mirrors.sjtug.sjtu.edu.cn/
        "https://mirrors.sjtug.sjtu.edu.cn/nix-channels/store"
        # status: https://mirrors.tuna.tsinghua.edu.cn/status/
        "https://mirrors.tuna.tsinghua.edu.cn/nix-channels/store"

        "https://cache.nixos.org"

        "https://nix-community.cachix.org"

        "https://cache.garnix.io"
      ];

      trusted-public-keys = [
        # the default public key of cache.nixos.org, it's built-in, no need to add it here
        "cache.nixos.org-1:6NCHdD59X431o0gWypbMrAURkbJ16ZPMQFGspcDShjY="

        "nix-community.cachix.org-1:mB9FSh9qf2dCimDSUo8Zy7bkq5CX+/rkCWyvRCYg3Fs="

        "cache.garnix.io:CTFPyKSLcx5RMJKfLo5EEPUObbA78b0YQ2DTCJXqr9g="
      ];
    };
  };

  environment.systemPackages = with pkgs; [
    nvd
    nix-output-monitor
    nil
    alejandra
  ];
}
