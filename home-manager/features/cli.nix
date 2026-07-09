{
  programs.atuin = {
    enable = true;
    settings = {
      update_check = false;
      style = "compact";
      store_failed = false;
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
  };
}
