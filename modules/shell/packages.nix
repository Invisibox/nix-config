{
  flake.modules.nixos.base = {pkgs, ...}: {
    environment.systemPackages = with pkgs; [
      wget
      curl
      htop
      btrfs-progs
      compsize
    ];
  };

  flake.modules.homeManager.shell = {pkgs, ...}: {
    home.packages = with pkgs; [
      aria2
      btop
      # dig
      # dnscontrol
      fastfetch
      fd
      ffmpeg
      hyperfine
      inetutils
      jq
      ripgrep
      socat
      tokei
      yazi

      # archives
      p7zip
      unrar
      unzip
      xz
      zip
    ];
  };
}
