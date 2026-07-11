{
  config,
  pkgs,
  ...
}: {
  # Allow unfree packages
  nixpkgs.config.allowUnfree = true;
  nixpkgs.config.permittedInsecurePackages = [
    "jitsi-meet-1.0.8792"
  ];

  # click-threading's legacy docs/conf.py imports the removed pkg_resources.
  # Restrict pytest to the package's actual test suite instead of collecting docs.
  nixpkgs.overlays = [
    (final: prev: {
      pythonPackagesExtensions =
        prev.pythonPackagesExtensions
        ++ [
          (pythonFinal: pythonPrev: {
            click-threading = pythonPrev.click-threading.overridePythonAttrs (old: {
              pytestFlags = (old.pytestFlags or []) ++ ["tests"];
            });

            # file 5.47 identifies compressed tar fixtures by their outer
            # compression MIME type, while patool's tests still expect x-tar.
            patool = pythonPrev.patool.overridePythonAttrs (old: {
              disabledTests =
                (old.disabledTests or [])
                ++ [
                  "test_py_tarfile_bz2"
                  "test_py_tarfile_bz2_file"
                  "test_tar_lzma"
                  "test_tar_xz"
                  "test_tar_bz2"
                  "test_tar_bz2_file"
                  "test_tar_lzip"
                  "test_tar_xz_file"
                  "test_mime_file"
                  "test_mime_file_bzip"
                ];
            });
          })
        ];
    })
  ];

  # do garbage collection weekly to keep disk usage low
  nix = {
    gc = {
      automatic = false;
      dates = "weekly";
      options = "--delete-older-than 7d";
    };

    # optimise = {
    #   automatic = true;
    #   dates = ["1w"];
    # };

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
        # # cache mirror located in China
        # # status: https://mirrors.ustc.edu.cn/status/
        "https://mirrors.ustc.edu.cn/nix-channels/store"
        # # status: https://mirrors.sjtug.sjtu.edu.cn/
        # # "https://mirrors.sjtug.sjtu.edu.cn/nix-channels/store"
        # # status: https://mirrors.tuna.tsinghua.edu.cn/status/
        "https://mirrors.tuna.tsinghua.edu.cn/nix-channels/store"

        "https://cache.nixos.org"

        "https://nix-community.cachix.org"

        "https://nix-gaming.cachix.org"

        "https://niri.cachix.org"
      ];

      trusted-public-keys = [
        # the default public key of cache.nixos.org, it's built-in, no need to add it here
        "cache.nixos.org-1:6NCHdD59X431o0gWypbMrAURkbJ16ZPMQFGspcDShjY="

        "nix-community.cachix.org-1:mB9FSh9qf2dCimDSUo8Zy7bkq5CX+/rkCWyvRCYg3Fs="

        "nix-gaming.cachix.org-1:nbjlureqMbRAxR1gJ/f3hxemL9svXaZF/Ees8vCUUs4="

        "niri.cachix.org-1:Wv0OmO7PsuocRKzfDoJ3mulSl7Z6oezYhGhR+3W2964="
      ];
    };
  };

  environment.systemPackages = with pkgs; [
    nvd
    nil
    nix-output-monitor
    alejandra
  ];

  programs.nh = {
    enable = true;
    clean = {
      enable = true;
      dates = "weekly";
      extraArgs = "--keep 3 --keep-since 7d";
    };
    flake = config.users.users.zh.home + "/Documents/nix-config";
  };

  systemd.tmpfiles.rules = [
    # nh writes build result symlinks under /tmp/nh-os*/result. On disk-backed
    # /tmp these can outlive reboots and keep old NixOS closures alive as GC roots.
    # Use mtime-based aging so root scans that refresh atime do not keep them forever.
    "e /tmp/nh-os* - - - mM:7d -"
  ];

  nix.channel.enable = false; # remove nix-channel related tools & configs, we use flakes instead.
}
