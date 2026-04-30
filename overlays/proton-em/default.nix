{
  fetchurl,
  lib,
  proton-ge-bin,
  writeScript,
}: let
  steamDisplayName = "Proton EM";
in
  (proton-ge-bin.override {
    inherit steamDisplayName;
  }).overrideAttrs
  (
    finalAttrs: _: {
      pname = "proton-em";
      version = "10.0-34";

      src = fetchurl {
        url = "https://github.com/Etaash-mathamsetty/Proton/releases/download/EM-${finalAttrs.version}/proton-EM-${finalAttrs.version}.tar.xz";
        hash = "sha256-2WgF5x+34PkViHVYYL10Jl0RGye9QMXhrNNXMBeVRro=";
      };

      dontUnpack = false;

      installPhase = ''
        runHook preInstall

        echo "${finalAttrs.pname} should not be installed into environments. Please use programs.steam.extraCompatPackages instead." > $out

        mkdir $steamcompattool
        cp -a ./. $steamcompattool/

        runHook postInstall
      '';

      preFixup = ''
        substituteInPlace "$steamcompattool/compatibilitytool.vdf" \
          --replace-fail "proton-EM-${finalAttrs.version}" "${steamDisplayName}"
        substituteInPlace "$steamcompattool/compatibilitytool.vdf" \
          --replace-fail "-proton" ""
      '';

      passthru.updateScript = writeScript "update-proton-em" ''
        #!/usr/bin/env nix-shell
        #!nix-shell -i bash -p curl jq common-updater-scripts
        set -euo pipefail

        repo="https://api.github.com/repos/Etaash-mathamsetty/Proton/releases?per_page=30"
        curl_fetch() {
          curl \
            --fail \
            --silent \
            --show-error \
            --location \
            --retry "''${CURL_RETRIES:-5}" \
            --retry-all-errors \
            --retry-delay "''${CURL_RETRY_DELAY:-2}" \
            --retry-max-time "''${CURL_RETRY_MAX_TIME:-120}" \
            --connect-timeout "''${CURL_CONNECT_TIMEOUT:-20}" \
            "$@"
        }

        release_info="$(
          curl_fetch "$repo" \
            | jq --raw-output 'map(select(.draft == false and .prerelease == false and (.tag_name | test("^EM-[0-9]+[.][0-9]+-[0-9A-Za-z]+$")))) | .[0] | .tag_name as $tag_name | ($tag_name | ltrimstr("EM-")) as $version | ([.assets[] | select(.name == ("proton-EM-" + $version + ".tar.xz"))] | first) as $tar_asset | ([.assets[] | select(.name == ("proton-EM-" + $version + ".sha256sum"))] | first // {}) as $sha256_asset | select($tar_asset.browser_download_url != null) | [$version, ($tar_asset.digest // ""), ($sha256_asset.browser_download_url // "")] | @tsv'
        )"
        IFS=$'\t' read -r version asset_digest sha256_url <<< "$release_info"
        digest_algo="''${asset_digest%%:*}"
        digest_hex="''${asset_digest#*:}"

        if [[ "$digest_algo" != sha256 || ! "$digest_hex" =~ ^[0-9A-Fa-f]{64}$ ]]; then
          if [[ -z "$sha256_url" ]]; then
            echo "error: no sha256 digest found for proton-em $version" >&2
            exit 1
          fi

          digest_hex="$(curl_fetch "$sha256_url" | sed -n '0,/^\([0-9A-Fa-f]\{64\}\).*/s//\1/p')"
        fi

        if [[ ! "$digest_hex" =~ ^[0-9A-Fa-f]{64}$ ]]; then
          echo "error: invalid sha256 digest for proton-em $version" >&2
          exit 1
        fi

        hash="$(nix hash convert --hash-algo sha256 --to sri "$digest_hex")"
        update-source-version proton-em "$version" "$hash"
      '';

      meta = {
        inherit
          (proton-ge-bin.meta)
          description
          license
          platforms
          sourceProvenance
          ;
        homepage = "https://github.com/Etaash-mathamsetty/Proton";
        maintainers = with lib.maintainers; [
          keenanweaver
        ];
      };
    }
  )
