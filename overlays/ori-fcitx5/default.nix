# /etc/nixos/pkgs/fcitx5-catppuccin.nix
{
  lib,
  stdenv,
  fetchFromGitHub,
}:
stdenv.mkDerivation {
  pname = "ori-fcitx5";
  version = "0.1.0";

  src = fetchFromGitHub {
    owner = "Reverier-Xu";
    repo = "Ori-fcitx5";
    rev = "d2cf5df";
    # 你的 fetchFromGitHub 请求依然在这里
    sha256 = "sha256-46O/wCRphjVkYCbr29QqyiGBG27u3UG2DnrInZSQkIA=";
  };

  installPhase = ''
    runHook preInstall

    mkdir -pv $out/share/fcitx5/themes/
    cp -rv Ori* $out/share/fcitx5/themes/

    runHook postInstall
  '';

  meta = with lib; {
    description = "This theme is just an attempt to round corners with svg theme.";
    homepage = "https://github.com/Reverier-Xu/Ori-fcitx5";
    license = licenses.mpl20;
    platforms = platforms.all;
  };
}
