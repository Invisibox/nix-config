{
  pkgs,
  inputs,
  lib,
  ...
}: {
  # 注意修改这里的用户名与用户目录
  home.username = "zh";
  home.homeDirectory = "/home/zh";

  # 直接将当前文件夹的配置文件，链接到 Home 目录下的指定位置
  # home.file.".config/i3/wallpaper.jpg".source = ./wallpaper.jpg;

  # 递归将某个文件夹中的文件，链接到 Home 目录下的指定位置
  # home.file.".config/i3/scripts" = {
  #   source = ./scripts;
  #   recursive = true;   # 递归整个文件夹
  #   executable = true;  # 将其中所有文件添加「执行」权限
  # };

  # 直接以 text 的方式，在 nix 配置文件中硬编码文件内容
  # home.file.".xxx".text = ''
  #     xxx
  # '';

  # 通过 home.packages 安装一些常用的软件
  # 这些软件将仅在当前用户下可用，不会影响系统级别的配置
  # 建议将所有 GUI 软件，以及与 OS 关系不大的 CLI 软件，都通过 home.packages 安装
  home.packages = with pkgs; [
    kdePackages.kate
    file-roller
    papirus-icon-theme
    fastfetch
    vscode
    obsidian
    zotero
    calibre
    readest
    termius
    tor-browser

    # kde-rounded-corners
    # inputs.kwin-effects-forceblur.packages.${pkgs.system}.default # Wayland
    # inputs.kwin-effects-forceblur.packages.${pkgs.system}.x11 # X11

    wpsoffice-cn
    kdePackages.okular
    gimp-with-plugins
    cherry-studio
    qimgv
    amberol
    gnome-calculator
    fluent-reader
    piliplus
    winboat
    discord
    spotify
    vial
    thunderbird
    qbittorrent-enhanced
    servo
    brave
    planify
    mangayomi
    fluffychat
    keyguard
    anki
    hmcl

    inputs.zen-browser.packages."${stdenv.hostPlatform.system}".default

    # archives
    zip
    xz
    unzip
    p7zip

    # utils
    eza # A modern replacement for ‘ls’
    fzf # A command-line fuzzy finder
    ripgrep
    socat
    fd
    jq
    pango
    yazi
    lazygit
    pkg-config
    devbox
    android-tools
    rar
    aircrack-ng
    hyperfine
    btop
    wl-clipboard
    graphviz
    inetutils
    texlive.combined.scheme-full
    nodejs

    qgnomeplatform
  ];

  home.sessionVariables = {
    EDITOR = "neovim";
  };

  home.pointerCursor = {
    gtk.enable = true;
    x11.enable = true;
    name = "Bibata-Modern-Ice";
    package = pkgs.bibata-cursors;
    size = 20;
  };

  # git 相关配置
  programs.git = {
    enable = true;
    settings = {
      user.name = "Invisibox";
      user.email = "admin@djdog.cc";
    };
  };

  imports = [
    ./dms
    ./fish
    ./nautilus
    ./zed
    ./mpv.nix
    ./kitty.nix
    ./starship.nix
    ./zsh/zsh.nix
  ];

  # KDE Connect
  services.kdeconnect.enable = true;

  gtk = {
    enable = true;
    iconTheme = {
      package = pkgs.papirus-icon-theme;
      name = "Papirus";
    };
  };

  qt = {
    enable = true;
    style.package = with pkgs; [darkly-qt5 darkly];
    platformTheme.name = "qtct";
  };

  programs.atuin = {
    enable = true;
    enableFishIntegration = true;
    settings = {
      update_check = false;
      style = "compact";
      save_failed_commands = "false";
      inline_height = 12;
      dialect = "us";
      keys = {
        scroll_exits = false;
        exit_past_line_start = false;
        accept_past_line_end = false;
      };
      history_filter = ["^\\s+"];
    };
  };

  programs.fzf = {
    enable = true;
    enableFishIntegration = true;
    defaultOptions = [
      "--with-shell='zsh -c'"
      "--multi"
      "--cycle"
      "--ansi"
      "--reverse"
      "--border=none"
      "--wrap"
      "--gap-line=―"
      "--pointer=' '"
      "--tabstop=4"
      "--prompt='» '"
      "--preview-label-pos=-2:bottom"
      "--preview-window=,wrap,border-left,cycle"
    ];
    colors = {
      "fg" = "-1"; # Text
      "bg" = "-1"; # Background
      "hl" = "1"; # Highlighted substrings
      "current-fg" = "-1"; # (fg+) Text (current line)
      "current-bg" = "5"; # (bg+) Background (current line)
      "current-hl" = "1"; # (hl+) Highlighted substrings (current line)
      "info" = "-1:dim"; # Info line (match counters)
      "border" = "8:dim"; # Border around the window (−−border and −−preview)
      "gutter" = "-1"; # Gutter on the left
      "query" = "-1:bold"; # (input−fg) Query string
      "prompt" = "1"; # Prompt
      "pointer" = "1"; # Pointer to the current line
      "marker" = "1"; # Multi−select marker
      "spinner" = "1"; # Streaming input indicator
    };
  };

  programs.eza = {
    enable = true;
    enableFishIntegration = true;
  };

  # This value determines the Home Manager release that your
  # configuration is compatible with. This helps avoid breakage
  # when a new Home Manager release introduces backwards
  # incompatible changes.
  #
  # You can update Home Manager without changing this value. See
  # the Home Manager release notes for a list of state version
  # changes in each release.
  home.stateVersion = "25.05";
}
