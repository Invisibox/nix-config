{...}: {
  programs.kitty = {
    enable = true;
    themeFile = "Nord";
    font = {
      name = "Maple Mono NF CN";
      size = 11;
    };
    settings = {
      confirm_os_window_close = 0;
      background_opacity = 0.6;
      # Let niri own the blur region; kitty's Wayland blur region can lag behind resizes.
      background_blur = 0;
      initial_window_width = 880;
      initial_window_height = 600;
      remember_window_size = "no";
      window_margin_width = 3;
      hide_window_decorations = "yes";
      cursor_trail = 3;
    };
  };
}
