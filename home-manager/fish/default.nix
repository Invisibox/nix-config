# home-manager/fish/default.nix

# 1. 改为标准的模块参数
{
  config,
  lib,
  pkgs,
  ...
}: let
  # 2. 使用 config.home.homeDirectory 来构建绝对路径
  #    注意：这里的路径要和你实际的目录结构完全一致
  link = f: config.lib.file.mkOutOfStoreSymlink "${config.home.homeDirectory}/Documents/nix-config/home-manager/fish/${f}";

  # shave 3ms off startup time by not calling the bin each time
  starshipInit =
    pkgs.runCommandLocal "fish starship init" {}
    ''
      ${lib.getExe config.programs.starship.package} init fish --print-full-init >$out 2>/dev/null
    '';
in {
  imports = [
    ./keybindings.nix
  ];

  programs.fish = {
    enable = true;

    loginShellInit =
      # fish
      ''
        status is-interactive; and cd /data
      '';

    interactiveShellInit =
      # fish
      ''
        source ${starshipInit}
        source ${link "./functions.fish"}
      '';
  };
}
