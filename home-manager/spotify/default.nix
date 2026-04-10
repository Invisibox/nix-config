{
  pkgs,
  inputs,
  ...
}: let
  spicePkgs = inputs.spicetify-nix.legacyPackages.${pkgs.stdenv.hostPlatform.system};
in {
  # Let spicetify-nix manage Spotify package installation.
  # Do not add pkgs.spotify separately.
  programs.spicetify = {
    enable = true;

    enabledExtensions = with spicePkgs.extensions; [
      fullAppDisplay
      loopyLoop
      shuffle
    ];

    enabledCustomApps = with spicePkgs.apps; [
      lyricsPlus
    ];

    theme = spicePkgs.themes.catppuccin;
    colorScheme = "mocha";
  };
}
