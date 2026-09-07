{
  config,
  lib,
  pkgs,
  ...
}: let
  cfg = config.local.apps.bitwarden;
  localUserName = config.local.user.name;
  bitwardenDesktop = cfg.package;
  nativeMessagingHost = pkgs.runCommand "bitwarden-desktop-native-messaging-host" {} ''
    host_dir="$out/lib/mozilla/native-messaging-hosts"
    chromium_dir="$out/etc/chromium/native-messaging-hosts"
    mkdir -p "$host_dir" "$chromium_dir"

    cat > "$host_dir/com.8bit.bitwarden.json" <<'EOF'
    {
      "name": "com.8bit.bitwarden",
      "description": "Bitwarden desktop application",
      "path": "${bitwardenDesktop}/libexec/desktop_proxy",
      "type": "stdio",
      "allowed_extensions": [
        "{446900e4-71c2-419f-a837-7ca9a4ac4e93}"
      ]
    }
    EOF

    cat > "$chromium_dir/com.8bit.bitwarden.json" <<'EOF'
    {
      "name": "com.8bit.bitwarden",
      "description": "Bitwarden desktop application",
      "path": "${bitwardenDesktop}/libexec/desktop_proxy",
      "type": "stdio",
      "allowed_origins": [
        "chrome-extension://nngceckbapebfimnlniiiahkandclblb/",
        "chrome-extension://jbkfoedolllekgbhcbcoahefnbanhhlh/"
      ]
    }
    EOF
  '';
in {
  options.local.apps.bitwarden = {
    enable = lib.mkEnableOption "Bitwarden Desktop with browser integration";

    package = lib.mkPackageOption pkgs "bitwarden-desktop" {};
  };

  config = lib.mkIf cfg.enable {
    security.polkit.enable = true;

    # Keep the package in the system profile so NixOS polkit links the
    # biometric policy shipped by bitwarden-desktop.
    environment.systemPackages = [bitwardenDesktop];

    # The native host is exposed to Zen (Firefox native messaging) and to
    # Chromium-family browsers through their system host directory.
    environment.etc = {
      "chromium/native-messaging-hosts/com.8bit.bitwarden.json".source = "${nativeMessagingHost}/etc/chromium/native-messaging-hosts/com.8bit.bitwarden.json";
      "opt/chrome/native-messaging-hosts/com.8bit.bitwarden.json".source = "${nativeMessagingHost}/etc/chromium/native-messaging-hosts/com.8bit.bitwarden.json";
      "opt/brave/native-messaging-hosts/com.8bit.bitwarden.json".source = "${nativeMessagingHost}/etc/chromium/native-messaging-hosts/com.8bit.bitwarden.json";
      "opt/brave.com/brave-origin-beta/native-messaging-hosts/com.8bit.bitwarden.json".source = "${nativeMessagingHost}/etc/chromium/native-messaging-hosts/com.8bit.bitwarden.json";
    };

    home-manager.users.${localUserName} = {
      programs.zen-browser.nativeMessagingHosts = [nativeMessagingHost];
    };
  };
}
