{pkgs, ...}: {
  programs.mpv = {
    enable = true;

    # 使用了 ffmpeg-full 以获得更全的编解码器支持，并启用了 Wayland
    package = (
      pkgs.mpv-unwrapped.wrapper {
        mpv = pkgs.mpv-unwrapped.override {
          ffmpeg = pkgs.ffmpeg-full;
          waylandSupport = true;
        };
        # 添加了 modernz 和 sponsorblock 脚本
        scripts = with pkgs.mpvScripts; [
          uosc
          thumbfast
          sponsorblock
        ];
      }
    );

    # mpv.conf
    config = {
      # --- 原有的配置 ---
      profile = "high-quality";
      "ytdl-format" = "bestvideo+bestaudio"; # 带有'-'的key需要用引号
      "cache-default" = 1000000;

      # --- 从 mpv.conf 迁移过来的配置 ---
      hwdec = "auto-safe"; # 硬解
      vo = "gpu"; # 使用 GPU 渲染
      "save-position-on-quit" = true; # 退出时记住播放位置 (布尔值 true 表示该选项开启)
      "no-input-builtin-bindings" = true; # 禁用内建快捷键
      "sub-auto" = "fuzzy"; # 自动模糊匹配字幕文件
      alang = "en,eng,chi,zho,zh,zh-CN,zh-TW,zh-HK,zh-MO"; # 优先音轨
      slang = "chi,zho,zh,zh-CN,zh-TW,zh-HK,zh-MO"; # 优先字幕轨
      osd-bar = "no"; # 禁用 OSD 状态栏
      border = "no"; # 禁用边框
      osd-font = "Noto Sans CJK SC"; # OSD 字体
    };

    # input.conf
    # 将每一行 "按键 命令" 转换为 "按键" = "命令"; 的格式
    bindings = {
      # --- 鼠标控制 ---
      "MBTN_LEFT" = "cycle pause";
      "MBTN_LEFT_DBL" = "cycle fullscreen"; # 左键双击 全屏/退出全屏
      "MBTN_RIGHT" = "cycle fullscreen"; # 右键 暂停/继续
      "MBTN_BACK" = "playlist-prev"; # 侧键向前 播放列表上一个
      "MBTN_FORWARD" = "playlist-next"; # 侧键向后 播放列表下一个
      "WHEEL_UP" = "add volume 5"; # 滚轮向上 音量+5
      "WHEEL_DOWN" = "add volume -5"; # 滚轮向下 音量-5

      # --- 触摸板/平滑滚动 (由于启用了KDE自然滚动，所以都是反向的） ---
      "AXIS_UP" = "add volume -1";
      "AXIS_DOWN" = "add volume 1";
      "AXIS_LEFT" = "seek 1";
      "AXIS_RIGHT" = "seek -1";

      # --- 基础控制 ---
      "ESC" = "set fullscreen no"; # ESC 退出全屏
      "SPACE" = "cycle pause"; # 空格 暂停/继续
      "ENTER" = "cycle fullscreen"; # 回车 全屏/退出全屏

      # --- 音量与寻道 ---
      "UP" = "add volume 5"; # 方向键上 音量+5
      "DOWN" = "add volume -5"; # 方向键下 音量-5
      "Shift+UP" = "add volume 10"; # 音量+10
      "Shift+DOWN" = "add volume -10"; # 音量-10
      "LEFT" = "seek -5"; # 方向键左 后退5秒
      "RIGHT" = "seek 5"; # 方向键右 前进5秒
      "Shift+LEFT" = "seek -60"; # 后退60秒
      "Shift+RIGHT" = "seek 87 exact"; # 前进87秒(带exact精确定位)

      # --- 音频与字幕同步 ---
      "Ctrl+UP" = "add audio-delay -0.1"; # 音频延迟-0.1
      "Ctrl+DOWN" = "add audio-delay +0.1"; # 音频延迟+0.1
      "Ctrl+LEFT" = "add sub-delay -0.1"; # 字幕延迟-0.1
      "Ctrl+RIGHT" = "add sub-delay 0.1"; # 字幕延迟+0.1

      # --- 播放列表与章节 ---
      "PGUP" = "playlist-prev"; # 播放列表上一个
      "PGDWN" = "playlist-next"; # 播放列表下一个
      "HOME" = "add chapter -1"; # 视频上一章节
      "END" = "add chapter 1"; # 视频下一章节

      # --- 其他功能 ---
      "t" = "cycle ontop"; # 设置窗口最前
      "=" = "screenshot video"; # 视频截图
      "z" = "set speed 1.0"; # 播放速度设为1
      "c" = "add speed 0.1"; # 播放速度+0.1
      "x" = "add speed -0.1"; # 播放速度-0.1
      "v" = "frame-back-step"; # 前一帧
      "b" = "frame-step"; # 后一帧
      "n" = "add sub-pos -1"; # 字幕上移1单位
      "m" = "add sub-pos +1"; # 字幕下移1单位
      "," = "add sub-scale -0.05"; # 字幕缩小5%
      "." = "add sub-scale +0.05"; # 字幕放大5%
      "d" = "cycle sub-visibility"; # 隐藏字幕/显示字幕
      "f" = "cycle mute"; # 静音/取消静音
      "TAB" = "script-binding stats/display-stats-toggle"; # 打开/关闭播放信息
    };
  };
}
