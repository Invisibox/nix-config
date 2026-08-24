{
  disko.devices.disk.system = {
    type = "disk";
    # Verify this path with lsblk before running disko; the target is erased.
    device = "/dev/nvme0n1";
    content = {
      type = "gpt";
      partitions = {
        ESP = {
          priority = 1;
          name = "ESP";
          size = "1G";
          type = "EF00";
          content = {
            type = "filesystem";
            format = "vfat";
            mountpoint = "/boot";
            mountOptions = ["umask=0077"];
          };
        };

        system = {
          size = "100%";
          content = {
            type = "btrfs";
            extraArgs = ["-f"];
            subvolumes = let
              mountOptions = [
                "compress=zstd:1"
                "discard=async"
                "noatime"
              ];
            in {
              "@root" = {
                mountpoint = "/";
                inherit mountOptions;
              };
              "@home" = {
                mountpoint = "/home";
                inherit mountOptions;
              };
              "@nix" = {
                mountpoint = "/nix";
                inherit mountOptions;
              };
              "@swap" = {
                mountpoint = "/.swapvol";
                mountOptions = [
                  "compress=no"
                  "noatime"
                ];
                swap.swapfile.size = "16G";
              };
            };
          };
        };
      };
    };
  };
}
