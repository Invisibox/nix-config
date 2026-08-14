{
  pkgs,
  inputs,
  ...
}: let
  llmAgents = inputs.llm-agents.packages.${pkgs.stdenv.hostPlatform.system};
in {
  # 通过 home.packages 安装一些常用的软件
  # 这些软件将仅在当前用户下可用，不会影响系统级别的配置
  # 建议将所有 GUI 软件，以及与 OS 关系不大的 CLI 软件，都通过 home.packages 安装
  home.packages = with pkgs; [
    file-roller
    papirus-icon-theme
    fastfetch
    vscode
    obsidian
    zotero
    papers
    folio
    # calibre
    readest
    termius
    tor-browser
    tsukimi
    pandoc

    # Replaced by llm-agents.nix packages below.
    # claude-code
    # codex
    # llmAgents.oh-my-codex
    llmAgents.omp
    llmAgents.pi
    llmAgents.codex
    llmAgents.claude-code
    llmAgents.oh-my-claudecode
    llmAgents.cc-switch-cli
    llmAgents.paseo-desktop
    ghostty

    aria2
    v2rayn
    # cherry-studio
    qimgv
    amberol
    gnome-calculator
    fluent-reader
    piliplus
    winbox
    discord
    _64gram
    vial
    motrix-next
    thunderbird
    qbittorrent-enhanced
    servo
    planify
    mangayomi
    # fluffychat
    # keyguard
    anki
    hmcl
    element-desktop
    # dig
    winboat

    inputs.zen-browser.packages."${stdenv.hostPlatform.system}".default

    # archives
    zip
    xz
    unzip
    p7zip
    rar

    curtail

    # utils
    eza # A modern replacement for ‘ls’
    fzf # A command-line fuzzy finder
    ripgrep
    socat
    fd
    jq
    pango
    yazi
    pkg-config
    devbox
    android-tools
    hyperfine
    btop
    tokei
    wl-clipboard
    graphviz
    inetutils
    cmake
    nodejs
    pnpm

    libsForQt5.qt5ct
    qt6Packages.qt6ct
  ];
}
