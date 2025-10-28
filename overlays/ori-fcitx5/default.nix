# /etc/nixos/pkgs/fcitx5-catppuccin.nix
{
  lib,
  stdenv,
  fetchFromGitHub,
}:
stdenv.mkDerivation rec {
  pname = "ori-fcitx5";
  version = "0.1.0";

  src = fetchFromGitHub {
    owner = "Reverier-Xu";
    repo = "Ori-fcitx5";
    rev = "d2cf5df";
    # 你的 fetchFromGitHub 请求依然在这里
    sha256 = "sha256-kE3A7U2T1QZ3/wA3ZqWfXvU7Y5uS2f9g8h7j6K5L4M3=";
  };

  installPhase = ''
    install -d $out/share/fcitx5/themes
    cp -r src/* $out/share/fcitx5/themes/
  '';

  meta = with lib; {
    description = "This theme is just an attempt to round corners with svg theme.";
    homepage = "https://github.com/Reverier-Xu/Ori-fcitx5";
    license = licenses.mpl2;
    platforms = platforms.all;
  };
}
