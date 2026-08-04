{
  lib,
  pkgs,
}: let
  pname = "oh-my-pi";
  version = "17.2.7";
in
  pkgs.stdenv.mkDerivation {
    inherit pname version;

    src = pkgs.fetchurl {
      url = "https://github.com/can1357/oh-my-pi/releases/download/v${version}/omp-linux-x64";
      hash = "sha256-bjgsgLCvWAFrD1N7YEo6KfHpEEq7SYcFKVNB44+9x3Q=";
    };

    dontUnpack = true;
    dontConfigure = true;
    dontBuild = true;
    dontStrip = true;
    doInstallCheck = true;

    nativeBuildInputs = [
      pkgs.autoPatchelfHook
    ];

    buildInputs = [
      pkgs.stdenv.cc.cc
    ];

    installPhase = ''
      install -Dm755 "$src" "$out/bin/omp"
    '';

    installCheckPhase = ''
      "$out/bin/omp" --version
    '';

    meta = {
      description = "Terminal coding agent with built-in ACP editor support";
      homepage = "https://omp.sh";
      license = lib.licenses.mit;
      mainProgram = "omp";
      platforms = ["x86_64-linux"];
      sourceProvenance = with lib.sourceTypes; [binaryNativeCode];
    };
  }
