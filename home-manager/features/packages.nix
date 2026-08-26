{
  pkgs,
  inputs,
  ...
}: let
  llmAgents = inputs.llm-agents.packages.${pkgs.stdenv.hostPlatform.system};
in {
  home.packages = with pkgs; [
    # AI coding assistants
    # Replaced by llm-agents.nix packages below.
    # llmAgents.oh-my-codex
    llmAgents.cc-switch-cli
    llmAgents.claude-code
    llmAgents.codex
    llmAgents.oh-my-claudecode
    llmAgents.omp
    llmAgents.paseo-desktop
    llmAgents.pi

    # development and build tools
    android-tools
    cmake
    devbox
    graphviz
    nodejs
    openssl
    pandoc
    pkg-config
    pnpm
    vscode

    # terminal and command-line tools
    btop
    compsize
    # dig
    eza # A modern replacement for 'ls'
    fastfetch
    fd
    fzf # A command-line fuzzy finder
    ghostty
    hyperfine
    inetutils
    jq
    pango
    ripgrep
    socat
    termius
    tokei
    wl-clipboard
    yazi

    # archives
    p7zip
    rar
    unzip
    xz
    zip

    # networking, downloads, and browsers
    aria2
    motrix-next
    qbittorrent-enhanced
    # servo
    tor-browser
    v2rayn

    # communication and news readers
    _64gram
    # cherry-studio
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
    mangayomi
    obsidian
    papers
    planify
    # readest
    zotero

    # media and images
    amberol
    curtail
    piliplus
    qimgv
    tsukimi

    # desktop and system tools
    # dnscontrol
    file-roller
    gnome-calculator
    hmcl
    resources
    vial
    winboat
    winbox

    # themes and Qt configuration
    libsForQt5.qt5ct
    papirus-icon-theme
    qt6Packages.qt6ct
  ];
}
