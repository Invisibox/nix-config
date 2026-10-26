{
  flake.modules.homeManager.desktop = {
    # Declarative MIME default app bindings.
    # This makes file type associations reproducible and prevents accidental overrides
    # (for example media players claiming inode/directory).
    xdg.mimeApps = {
      enable = true;

      defaultApplications = {
        # File manager
        "inode/directory" = ["org.gnome.Nautilus.desktop"];

        # Browser and URL schemes
        "text/html" = ["zen-beta.desktop"];
        "application/xhtml+xml" = ["zen-beta.desktop"];
        "x-scheme-handler/http" = ["zen-beta.desktop"];
        "x-scheme-handler/https" = ["zen-beta.desktop"];

        # Documents and text
        "application/pdf" = ["onlyoffice-desktopeditors.desktop"];
        "text/plain" = ["dev.zed.Zed.desktop"];
        "text/markdown" = ["dev.zed.Zed.desktop"];
        "application/json" = ["dev.zed.Zed.desktop"];

        # Images
        "image/png" = ["qimgv.desktop"];
        "image/jpeg" = ["qimgv.desktop"];
        "image/webp" = ["qimgv.desktop"];
        "image/avif" = ["qimgv.desktop"];
        "image/svg+xml" = ["qimgv.desktop"];

        # Euphonica uses the MPD library; mpv handles opening media files.
        "audio/mpeg" = ["mpv.desktop"];
        "audio/flac" = ["mpv.desktop"];
        "audio/ogg" = ["mpv.desktop"];
        "audio/wav" = ["mpv.desktop"];
        "audio/x-wav" = ["mpv.desktop"];
        "audio/x-m4a" = ["mpv.desktop"];
        "audio/mp4" = ["mpv.desktop"];
        "video/mp4" = ["mpv.desktop"];
        "video/x-matroska" = ["mpv.desktop"];

        # Mail links
        "x-scheme-handler/mailto" = ["thunderbird.desktop"];
      };
    };
  };
}
