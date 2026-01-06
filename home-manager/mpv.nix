{pkgs, ...}: {
  programs.mpv = {
    enable = true;

    # 使用 mpv.override 替代 mpv-unwrapped.wrapper
    package = pkgs.mpv.override {
      # 覆盖底层的 mpv-unwrapped，使用 ffmpeg-full 和启用 Wayland
      mpv-unwrapped = pkgs.mpv-unwrapped.override {
        ffmpeg = pkgs.ffmpeg-full;
        waylandSupport = true;
      };
      # 添加脚本
      scripts = with pkgs.mpvScripts; [
        uosc
        thumbfast
        sponsorblock
      ];
    };

    # mpv.conf
    config = {
      # --- 原有的配置 ---
      profile = "high-quality";
      "ytdl-format" = "bestvideo+bestaudio";
      "cache-default" = 1000000;

      # --- 从 mpv.conf 迁移过来的配置 ---
      hwdec = "auto-safe";
      vo = "gpu";
      "save-position-on-quit" = true;
      "no-input-builtin-bindings" = true;
      "sub-auto" = "fuzzy";
      alang = "en,eng,chi,zho,zh,zh-CN,zh-TW,zh-HK,zh-MO";
      slang = "chi,zho,zh,zh-CN,zh-TW,zh-HK,zh-MO";
      osd-bar = "no";
      border = "no";
      osd-font = "Noto Sans CJK SC";
      sub-font = "Noto Sans CJK SC";
    };

    # input.conf
    bindings = {
      # --- 鼠标控制 ---
      "MBTN_LEFT" = "cycle pause";
      "MBTN_LEFT_DBL" = "cycle fullscreen";
      "MBTN_RIGHT" = "cycle fullscreen";
      "MBTN_BACK" = "playlist-prev";
      "MBTN_FORWARD" = "playlist-next";
      "WHEEL_UP" = "add volume 5";
      "WHEEL_DOWN" = "add volume -5";

      # --- 触摸板/平滑滚动 ---
      "AXIS_UP" = "add volume -1";
      "AXIS_DOWN" = "add volume 1";
      "AXIS_LEFT" = "seek 1";
      "AXIS_RIGHT" = "seek -1";

      # --- 基础控制 ---
      "ESC" = "set fullscreen no";
      "SPACE" = "cycle pause";
      "ENTER" = "cycle fullscreen";

      # --- 音量与寻道 ---
      "UP" = "add volume 5";
      "DOWN" = "add volume -5";
      "Shift+UP" = "add volume 10";
      "Shift+DOWN" = "add volume -10";
      "LEFT" = "seek -5";
      "RIGHT" = "seek 5";
      "Shift+LEFT" = "seek -60";
      "Shift+RIGHT" = "seek 87 exact";

      # --- 音频与字幕同步 ---
      "Ctrl+UP" = "add audio-delay -0.1";
      "Ctrl+DOWN" = "add audio-delay +0.1";
      "Ctrl+LEFT" = "add sub-delay -0.1";
      "Ctrl+RIGHT" = "add sub-delay 0.1";

      # --- 播放列表与章节 ---
      "PGUP" = "playlist-prev";
      "PGDWN" = "playlist-next";
      "HOME" = "add chapter -1";
      "END" = "add chapter 1";

      # --- 其他功能 ---
      "t" = "cycle ontop";
      "=" = "screenshot video";
      "z" = "set speed 1.0";
      "c" = "add speed 0.1";
      "x" = "add speed -0.1";
      "v" = "frame-back-step";
      "b" = "frame-step";
      "n" = "add sub-pos -1";
      "m" = "add sub-pos +1";
      "," = "add sub-scale -0.05";
      "." = "add sub-scale +0.05";
      "d" = "cycle sub-visibility";
      "f" = "cycle mute";
      "TAB" = "script-binding stats/display-stats-toggle";
    };
  };
}
