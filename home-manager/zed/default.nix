{...}: {
  programs.zed-editor = {
    enable = true;
    extensions = [
      "nix"
      "toml"
      "rust"
      "catppuccin-icons"
      "macos-classic"
    ];
    userSettings = {
      theme = {
        mode = "system";
        dark = "macOS Classic Dark";
        light = "macOS Classic Light";
      };
      icon_theme = {
        mode = "system";
        dark = "Catppuccin Mocha";
        light = "Catppuccin Latte";
      };
      ui_font_family = "Sarasa Gothic SC";
      ui_font_fallbacks = ["Sarasa Gothic SC"];
      buffer_font_family = "FiraCode Nerd Font";
      buffer_font_fallbacks = ["Sarasa Gothic SC"];
      buffer_font_size = 16;
      terminal = {
        font_family = "JetBrainsMono Nerd Font";
        font_size = 16;
      };
      minimap = {
        show = "auto";
        thumb = "hover";
      };
      agent_servers = {
        codex-acp = {
          type = "registry";
        };
      };
      lsp = {
        nil = {
          initialization_options = {
            formatting.command = ["alejandra"];
          };
        };
        nix = {
          binary = {
            path_lookup = true;
          };
        };
      };
      languages = {
        Nix = {
          tab_size = 2;
          language_servers = [
            "nil"
          ];
        };
      };
      vim_mode = true;
      relative_line_numbers = "wrapped";
    };
  };
}
