{inputs, username, host, ...}: {
  imports = [
    ./hyprland                        # window manager
    ./kitty.nix                       # terminal
    ./swayosd.nix                     # brightness / volume wiget
    ./swaync/swaync.nix               # notification deamon
    ./packages.nix                    # other packages
    ./rofi.nix                        # launcher
    ./swaylock.nix                    # lock screen
    ./waybar                          # status bar
    ./fastfetch.nix                   # fetch tool
    ./steam.nix                       # steam
  ];
}