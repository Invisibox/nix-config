{
  pnpm,
  fetchPnpmDeps,
  pnpmConfigHook,
  nodejs,
  stdenv,
  clang,
  buildGoModule,
  fetchFromGitHub,
  lib,
  daeuniverse,
}: let
  upstreamMetadata = (builtins.fromJSON (builtins.readFile "${daeuniverse}/metadata.json")).daed.release;
  metadata =
    upstreamMetadata
    // {
      # daeuniverse/flake.nix rev 967208d ships a stale pnpmDepsHash for daed v1.24.0.
      pnpmDepsHash = "sha256-+l10kTcwnBU4/YRiFf21viMYLJGDcpG0A3+z+zJQBtg=";
    };
  pname = "daed";
  inherit (metadata) version;
  src = fetchFromGitHub {
    owner = "daeuniverse";
    repo = "daed";
    inherit (metadata) rev hash;
    fetchSubmodules = true;
  };

  web = stdenv.mkDerivation {
    inherit pname version src;

    pnpmDeps = fetchPnpmDeps {
      inherit
        pname
        version
        src
        pnpm
        ;
      fetcherVersion = 3;
      hash = metadata.pnpmDepsHash;
    };

    nativeBuildInputs = [
      nodejs
      pnpm
      pnpmConfigHook
    ];

    postPatch = ''
      substituteInPlace package.json \
        --replace-fail '"packageManager": "pnpm@10.24.0"' '"packageManager": "pnpm@${pnpm.version}"'
    '';

    buildPhase = ''
      runHook preBuild
      export NODE_OPTIONS=--max-old-space-size=4096
      pnpm build
      runHook postBuild
    '';

    installPhase = ''
      runHook preInstall
      mkdir -p $out
      cp -R apps/web/dist/* $out/
      runHook postInstall
    '';
  };
in
  buildGoModule rec {
    inherit pname version src;
    sourceRoot = "${src.name}/wing";

    inherit (metadata) vendorHash;
    proxyVendor = true;

    nativeBuildInputs = [clang];

    hardeningDisable = ["zerocallusedregs"];

    prePatch = ''
      substituteInPlace Makefile \
        --replace-fail /bin/bash /bin/sh

      # ${web} does not have write permission.
      mkdir dist
      cp -r ${web}/* dist
      chmod -R 755 dist
    '';

    buildPhase = ''
      runHook preBuild

      make CFLAGS="-D__REMOVE_BPF_PRINTK -fno-stack-protector -Wno-unused-command-line-argument" \
        NOSTRIP=y \
        WEB_DIST=dist \
        AppName=${pname} \
        VERSION=${version} \
        OUTPUT=$out/bin/daed \
        bundle

      runHook postBuild
    '';

    postInstall = ''
      install -Dm444 $src/install/daed.service -t $out/lib/systemd/system
      substituteInPlace $out/lib/systemd/system/daed.service \
        --replace-fail /usr/bin $out/bin
    '';

    meta = {
      description = "Modern dashboard with dae";
      homepage = "https://github.com/daeuniverse/daed";
      license = lib.licenses.mit;
      maintainers = with lib.maintainers; [oluceps];
      platforms = lib.platforms.linux;
      mainProgram = "daed";
    };
  }
