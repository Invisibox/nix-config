{inputs, ...}: {
  flake.modules.nixos.dev = {pkgs, ...}: {
    environment.systemPackages = with pkgs; [
      git
      bun
      uv
      gcc
      go
      libgcc
      ncurses
    ];

    programs.neovim = {
      enable = true;
      vimAlias = true;
    };
  };

  flake.modules.homeManager.dev = {pkgs, ...}: let
    llmAgents = inputs.llm-agents.packages.${pkgs.stdenv.hostPlatform.system};
  in {
    home.packages = with pkgs; [
      # AI coding assistants
      llmAgents.cc-switch-cli
      llmAgents.claude-code
      llmAgents.codex
      llmAgents.omp
      # llmAgents.pi

      # development and build tools
      android-tools
      cmake
      # devbox
      graphviz
      nodejs
      openssl
      # pandoc
      pkg-config
      pnpm
      vscode
    ];
  };
}
