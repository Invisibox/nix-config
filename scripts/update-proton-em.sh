#!/usr/bin/env bash
set -euo pipefail

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
target_file="${repo_root}/modules/apps/proton-em/package.nix"
api_url="https://api.github.com/repos/Etaash-mathamsetty/Proton/releases?per_page=30"
channel="${PROTON_EM_CHANNEL:-stable}"
requested_version="${PROTON_EM_VERSION:-}"

if [[ ! -f "${target_file}" ]]; then
  echo "error: target file not found: ${target_file}" >&2
  exit 1
fi

for cmd in curl head jq nix sed; do
  if ! command -v "${cmd}" >/dev/null 2>&1; then
    echo "error: missing command: ${cmd}" >&2
    exit 1
  fi
done

case "${channel}" in
  stable | latest) ;;
  *)
    echo "error: unsupported PROTON_EM_CHANNEL: ${channel}" >&2
    echo "supported channels: stable, latest" >&2
    exit 1
    ;;
esac

github_headers=(-H "Accept: application/vnd.github+json" -H "X-GitHub-Api-Version: 2022-11-28")
if [[ -n "${GITHUB_TOKEN:-}" ]]; then
  github_headers+=(-H "Authorization: Bearer ${GITHUB_TOKEN}")
fi

curl_fetch() {
  curl \
    --fail \
    --silent \
    --show-error \
    --location \
    --retry "${CURL_RETRIES:-5}" \
    --retry-all-errors \
    --retry-delay "${CURL_RETRY_DELAY:-2}" \
    --retry-max-time "${CURL_RETRY_MAX_TIME:-120}" \
    --connect-timeout "${CURL_CONNECT_TIMEOUT:-20}" \
    "$@"
}

releases_json="$(curl_fetch "${github_headers[@]}" "${api_url}")"

release_info="$(
  jq -r --arg requested_version "${requested_version}" --arg channel "${channel}" '
    first(
      .[]
      | select(.draft == false)
      | select($requested_version != "" or .prerelease == false)
      | . as $release
      | ($release.tag_name // "") as $tag_name
      | select($tag_name | startswith("EM-"))
      | ($tag_name | ltrimstr("EM-")) as $version
      | select(
          if $requested_version != "" then
            ($requested_version == $tag_name or $requested_version == $version)
          elif $channel == "stable" then
            ($tag_name | test("^EM-[0-9]+[.][0-9]+-[0-9A-Za-z]+$"))
          else
            true
          end
        )
      | (
          [$release.assets[] | select(.name == ("proton-EM-" + $version + ".tar.xz"))]
          | first
        ) as $tar_asset
      | (
          [$release.assets[] | select(.name == ("proton-EM-" + $version + ".sha256sum"))]
          | first // {}
        ) as $sha256_asset
      | select($tar_asset.browser_download_url != null)
      | [$tag_name, $version, $tar_asset.browser_download_url, ($tar_asset.digest // ""), ($sha256_asset.browser_download_url // "")]
      | @tsv
    ) // empty
  ' <<<"${releases_json}"
)"

if [[ -z "${release_info}" ]]; then
  if [[ -n "${requested_version}" ]]; then
    echo "error: unable to find Proton EM release: ${requested_version}" >&2
  else
    echo "error: unable to find Proton EM release for channel: ${channel}" >&2
  fi
  exit 1
fi

IFS=$'\t' read -r tag_name version asset_url _asset_digest _sha256_url <<<"${release_info}"

hash="$(nix store prefetch-file --json --unpack "${asset_url}" | jq -r '.hash')"

if [[ -z "${hash}" || "${hash}" == "null" ]]; then
  echo "error: unable to determine hash for ${asset_url}" >&2
  exit 1
fi

current_version="$(sed -n 's/^  version = "\(.*\)";$/\1/p' "${target_file}" | head -n1)"
current_hash="$(sed -n 's/^    hash = "\(sha256-[^"]*\)";$/\1/p' "${target_file}" | head -n1)"

if [[ -z "${current_version}" || -z "${current_hash}" ]]; then
  echo "error: unable to locate current version/hash in ${target_file}" >&2
  exit 1
fi

if [[ "${current_version}" == "${version}" && "${current_hash}" == "${hash}" ]]; then
  echo "proton-em is already up to date (${version})"
  exit 0
fi

sed -Ei 's|^  version = "[^"]+";$|  version = "'"${version}"'";|' "${target_file}"
sed -Ei 's|^    hash = "sha256-[^"]+";$|    hash = "'"${hash}"'";|' "${target_file}"

updated_version="$(sed -n 's/^  version = "\(.*\)";$/\1/p' "${target_file}" | head -n1)"
updated_hash="$(sed -n 's/^    hash = "\(sha256-[^"]*\)";$/\1/p' "${target_file}" | head -n1)"

if [[ "${updated_version}" != "${version}" || "${updated_hash}" != "${hash}" ]]; then
  echo "error: failed to update version/hash in ${target_file}" >&2
  exit 1
fi

echo "updated ${target_file}"
echo "  channel: ${channel}"
echo "  tag:     ${tag_name}"
echo "  version: ${current_version:-unknown} -> ${version}"
echo "  hash:    ${current_hash:-unknown} -> ${hash}"
echo "  asset:   ${asset_url}"
