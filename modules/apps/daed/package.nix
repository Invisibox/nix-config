{
  pkgs,
  inputs,
}: let
  daedFetchPnpmDeps = args:
    pkgs.fetchPnpmDeps (
      args
      // {
        hash = "sha256-9KfaLlAo//prhA26SQIbEnsk5b7h8+N3V5syickLTWM=";
        NIX_NPM_REGISTRY = "https://registry.npmmirror.com";
        prePnpmInstall =
          (args.prePnpmInstall or "")
          + ''
            export NIX_NPM_REGISTRY=https://registry.npmmirror.com
            printf '\nminimumReleaseAge: 0\nregistry: https://registry.npmmirror.com/\n' >> pnpm-workspace.yaml
            pnpm config set fetch-timeout 600000
            pnpm config set fetch-retries 5
            pnpm config set fetch-retry-maxtimeout 120000
          '';
      }
    );
  daedStdenv =
    pkgs.stdenv
    // {
      mkDerivation = args:
        pkgs.stdenv.mkDerivation (
          args
          // {
            NODE_OPTIONS = "--max-old-space-size=4096";
            TURBO_TELEMETRY_DISABLED = "1";
          }
        );
    };
in
  pkgs.callPackage "${inputs.daeuniverse.outPath}/daed/package.nix" {
    pnpm = pkgs.pnpm_10;
    stdenv = daedStdenv;
    fetchPnpmDeps = daedFetchPnpmDeps;
  }
