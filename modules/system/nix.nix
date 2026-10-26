{
  flake.modules.nixos.base = {
    config,
    pkgs,
    ...
  }: {
    # Allow unfree packages
    nixpkgs.config.allowUnfree = true;

    nixpkgs.overlays = [
      (final: prev: {
        pythonPackagesExtensions =
          prev.pythonPackagesExtensions
          ++ [
            (pythonFinal: pythonPrev: {
              # The Sphinx hook expands this value as a shell word list.
              # With structuredAttrs, a Nix list exposes only its first item.
              reuse = pythonPrev.reuse.overridePythonAttrs (_: {
                sphinxBuilders = "html man";
              });
            })
          ];
      })
    ];

    # GC is handled by programs.nh.clean (weekly, --keep 3 --keep-since 7d).
    nix = {
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

          "https://invisibox.cachix.org"

          "https://nix-community.cachix.org"

          "https://nix-gaming.cachix.org"

          "https://cache.garnix.io"

          "https://niri-epireyn.cachix.org"

          "https://noctalia.cachix.org"

          "https://cache.numtide.com"

          "https://cache.lantian.pub/lantian"

          "https://nyx-cache.chaotic.cx/"
        ];

        trusted-public-keys = [
          # the default public key of cache.nixos.org, it's built-in, no need to add it here
          "cache.nixos.org-1:6NCHdD59X431o0gWypbMrAURkbJ16ZPMQFGspcDShjY="

          "invisibox.cachix.org-1:Z0N2eK66tu3OyRiImOR1yHcQmy8DK/6CRCkVxQqvJYk="

          "nix-community.cachix.org-1:mB9FSh9qf2dCimDSUo8Zy7bkq5CX+/rkCWyvRCYg3Fs="

          "nix-gaming.cachix.org-1:nbjlureqMbRAxR1gJ/f3hxemL9svXaZF/Ees8vCUUs4="

          "cache.garnix.io:CTFPyKSLcx5RMJKfLo5EEPUObbA78b0YQ2DTCJXqr9g="

          "niri-epireyn.cachix.org-1:tlVyFN7CtsDT+ZcLPS+ekFWeT1X6X4OqvWqbBMyIzFA="

          "noctalia.cachix.org-1:pCOR47nnMEo5thcxNDtzWpOxNFQsBRglJzxWPp3dkU4="

          "niks3.numtide.com-1:DTx8wZduET09hRmMtKdQDxNNthLQETkc/yaX7M4qK0g="

          "lantian:WVGO7vsRMSEN+h7Lp7kv6SAmrkEXgUGbbXm7jMDjBuQ="

          "nyx-cache.chaotic.cx:dJxTrgMC3V3cFfyIiBQDQorG6k1LsqurH/srpMSq7qk="
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
  };
}
