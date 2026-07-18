{
  lib,
  pkgs,
}: let
  pname = "oh-my-pi";
  version = "17.0.2";
in
  pkgs.stdenv.mkDerivation {
    inherit pname version;

    src = pkgs.fetchurl {
      url = "https://github.com/can1357/oh-my-pi/releases/download/v${version}/omp-linux-x64";
      hash = "sha256-ZZUsz4eI8plWICA4cVJVNFMO5RFlRwL4IH+ivSOL10M=";
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
