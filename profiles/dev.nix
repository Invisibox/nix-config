{pkgs, ...}: {
  local.dev.nix-ld.enable = true;
  local.virtualisation.enable = true;

  # List packages installed in system profile. To search, run:
  # $ nix search wget
  environment.systemPackages = with pkgs; [
    git
    wget
    curl
    htop
    eza
    bun
    uv
    gcc
    go
    libgcc
    ncurses
    btrfs-progs
    compsize
    xsettingsd
    xrdb
    xdg-desktop-portal-gtk
    vulkan-tools
    pavucontrol
    dconf-editor
  ];

  programs.neovim = {
    enable = true;
    vimAlias = true;
  };
}
