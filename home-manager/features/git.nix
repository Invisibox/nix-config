{ pkgs, ... }:
{
  # git 相关配置
  programs.gh = {
    enable = true;
    package = pkgs.gh;
    settings.git_protocol = "https";

    gitCredentialHelper = {
      enable = true;
      hosts = [ "https://github.com" ];
    };
  };

  programs.git = {
    enable = true;
    settings = {
      user.name = "Invisibox";
      user.email = "admin@djdog.cc";
    };
  };
}
