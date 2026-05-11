#!/usr/bin/env bash
set -euo pipefail

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
target_file="${repo_root}/modules/apps/bottles/default.nix"
api_url="https://api.github.com/repos/bottlesdevs/winebridge/releases/latest"

if [[ ! -f "${target_file}" ]]; then
  echo "error: target file not found: ${target_file}" >&2
  exit 1
fi

for cmd in curl jq nix sed; do
  if ! command -v "${cmd}" >/dev/null 2>&1; then
    echo "error: missing command: ${cmd}" >&2
    exit 1
  fi
done

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

release_json="$(curl_fetch "${github_headers[@]}" "${api_url}")"

release_info="$(
  jq -r '
    . as $release
    | (
        [$release.assets[] | select(.name | test("^WineBridge-.*[.]tar[.]xz$"))]
        | first
      ) as $asset
    | select($release.draft == false)
    | select($asset.browser_download_url != null)
    | [$release.tag_name, $asset.name, $asset.browser_download_url]
    | @tsv
  ' <<<"${release_json}"
)"

if [[ -z "${release_info}" ]]; then
  echo "error: unable to find a WineBridge tar.xz asset in the latest release" >&2
  exit 1
fi

IFS=$'\t' read -r release_tag asset_name asset_url <<<"${release_info}"

prefetch_json="$(nix store prefetch-file --json --unpack "${asset_url}")"
hash="$(jq -r '.hash' <<<"${prefetch_json}")"
store_path="$(jq -r '.storePath' <<<"${prefetch_json}")"
version="$(sed -n '1{s/[[:space:]]*$//;p;q}' "${store_path}/VERSION" 2>/dev/null || true)"

if [[ -z "${version}" ]]; then
  version="${release_tag#v}"
fi

if [[ -z "${hash}" || "${hash}" == "null" ]]; then
  echo "error: unable to determine hash for ${asset_url}" >&2
  exit 1
fi

current_version="$(sed -n 's/^  winebridgeVersion = "\(.*\)";$/\1/p' "${target_file}" | head -n1)"
current_release_tag="$(sed -n 's/^  winebridgeReleaseTag = "\(.*\)";$/\1/p' "${target_file}" | head -n1)"
current_asset="$(sed -n 's/^  winebridgeAsset = "\(.*\)";$/\1/p' "${target_file}" | head -n1)"
current_hash="$(sed -n 's/^  winebridgeHash = "\(sha256-[^"]*\)";$/\1/p' "${target_file}" | head -n1)"

if [[ "${current_version}" == "${version}" \
  && "${current_release_tag}" == "${release_tag}" \
  && "${current_asset}" == "${asset_name}" \
  && "${current_hash}" == "${hash}" ]]; then
  echo "bottles winebridge is already up to date (${version})"
  exit 0
fi

sed -Ei 's|^  winebridgeVersion = "[^"]+";$|  winebridgeVersion = "'"${version}"'";|' "${target_file}"
sed -Ei 's|^  winebridgeReleaseTag = "[^"]+";$|  winebridgeReleaseTag = "'"${release_tag}"'";|' "${target_file}"
sed -Ei 's|^  winebridgeAsset = "[^"]+";$|  winebridgeAsset = "'"${asset_name}"'";|' "${target_file}"
sed -Ei 's|^  winebridgeHash = "sha256-[^"]+";$|  winebridgeHash = "'"${hash}"'";|' "${target_file}"

echo "updated ${target_file}"
echo "  release: ${current_release_tag:-unknown} -> ${release_tag}"
echo "  version: ${current_version:-unknown} -> ${version}"
echo "  asset:   ${current_asset:-unknown} -> ${asset_name}"
echo "  hash:    ${current_hash:-unknown} -> ${hash}"
echo "  url:     ${asset_url}"
