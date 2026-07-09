{
  # Declarative MIME default app bindings.
  # This makes file type associations reproducible and prevents accidental overrides
  # (for example Amberol claiming inode/directory).
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
      "application/pdf" = ["wps-office-pdf.desktop"];
      "text/plain" = ["org.kde.kate.desktop"];
      "text/markdown" = ["org.kde.kate.desktop"];
      "application/json" = ["org.kde.kate.desktop"];

      # Images
      "image/png" = ["qimgv.desktop"];
      "image/jpeg" = ["qimgv.desktop"];
      "image/webp" = ["qimgv.desktop"];
      "image/avif" = ["qimgv.desktop"];
      "image/svg+xml" = ["qimgv.desktop"];

      # Media
      "audio/mpeg" = ["io.bassi.Amberol.desktop"];
      "audio/flac" = ["io.bassi.Amberol.desktop"];
      "audio/ogg" = ["io.bassi.Amberol.desktop"];
      "audio/wav" = ["io.bassi.Amberol.desktop"];
      "audio/x-wav" = ["io.bassi.Amberol.desktop"];
      "audio/x-m4a" = ["io.bassi.Amberol.desktop"];
      "audio/mp4" = ["io.bassi.Amberol.desktop"];
      "video/mp4" = ["mpv.desktop"];
      "video/x-matroska" = ["mpv.desktop"];

      # Mail links
      "x-scheme-handler/mailto" = ["thunderbird.desktop"];
    };

    associations.removed = {
      "inode/directory" = ["io.bassi.Amberol.desktop"];
    };
  };
}
