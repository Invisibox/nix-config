{
  flake.modules.homeManager.apps = {pkgs, ...}: {
    home.packages = with pkgs; [
      # terminal emulators and remote connections
      ghostty
      termius

      # networking, downloads, and browsers
      motrix
      qbittorrent-enhanced
      resilio-sync
      # servo
      tor-browser
      v2rayn

      # communication and news readers
      _64gram
      discord
      element-desktop
      # fluffychat
      # fluent-reader
      # keyguard
      newsflash
      thunderbird

      # knowledge management and productivity
      anki
      # calibre
      folio
      # mangayomi
      obsidian
      papers
      planify
      # readest
      typst
      # zotero

      # media and images
      amberol
      # curtail
      piliplus
      qimgv
      tsukimi

      # desktop and system tools
      file-roller
      galaxy-buds-client
      gnome-calculator
      # hmcl
      resources
      # vial
      # winboat
      winbox
    ];
  };
}
