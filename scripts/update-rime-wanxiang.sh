#!/usr/bin/env bash
set -euo pipefail

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
target_file="${repo_root}/overlays/default.nix"
wanxiang_api_url="https://api.github.com/repos/amzxyz/rime_wanxiang/releases/latest"
gram_api_url="https://api.github.com/repos/amzxyz/RIME-LMDG/releases/tags/LTS"
wanxiang_asset_name="${WANXIANG_ASSET:-rime-wanxiang-base.zip}"
gram_asset_name="wanxiang-lts-zh-hans.gram"

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

hash_from_asset() {
  local url="$1"
  local digest="$2"
  local hash=""

  if [[ -n "${digest}" && "${digest}" != "null" ]]; then
    local digest_algo="${digest%%:*}"
    local digest_hex="${digest#*:}"
    if [[ "${digest_algo}" == "sha256" && "${digest_hex}" =~ ^[0-9A-Fa-f]{64}$ ]]; then
      hash="$(nix hash convert --hash-algo sha256 --to sri "${digest_hex}" 2>/dev/null || true)"
    fi
  fi

  if [[ -z "${hash}" || "${hash}" == "null" ]]; then
    hash="$(nix store prefetch-file --json "${url}" | jq -r '.hash')"
  fi

  if [[ -z "${hash}" || "${hash}" == "null" ]]; then
    echo "error: unable to determine hash for ${url}" >&2
    exit 1
  fi

  printf '%s\n' "${hash}"
}

wanxiang_release_json="$(curl -fsSL "${github_headers[@]}" "${wanxiang_api_url}")"
tag_name="$(jq -r '.tag_name // empty' <<<"${wanxiang_release_json}")"
if [[ -z "${tag_name}" ]]; then
  echo "error: unable to read latest wanxiang release tag" >&2
  exit 1
fi

version="${tag_name#v}"
wanxiang_asset_info="$(jq -r --arg name "${wanxiang_asset_name}" '
  (
    .assets[]
    | select(.name == $name)
    | [.browser_download_url, (.digest // "")]
    | @tsv
  ) // empty
' <<<"${wanxiang_release_json}")"

if [[ -z "${wanxiang_asset_info}" ]]; then
  echo "error: unable to find ${wanxiang_asset_name} in ${tag_name}" >&2
  exit 1
fi

IFS=$'\t' read -r wanxiang_asset_url wanxiang_asset_digest <<<"${wanxiang_asset_info}"
wanxiang_hash="$(hash_from_asset "${wanxiang_asset_url}" "${wanxiang_asset_digest}")"

gram_release_json="$(curl -fsSL "${github_headers[@]}" "${gram_api_url}")"
gram_asset_info="$(jq -r --arg name "${gram_asset_name}" '
  (
    .assets[]
    | select(.name == $name)
    | [.browser_download_url, (.digest // "")]
    | @tsv
  ) // empty
' <<<"${gram_release_json}")"

if [[ -z "${gram_asset_info}" ]]; then
  echo "error: unable to find ${gram_asset_name} in LTS release" >&2
  exit 1
fi

IFS=$'\t' read -r gram_asset_url gram_asset_digest <<<"${gram_asset_info}"
gram_hash="$(hash_from_asset "${gram_asset_url}" "${gram_asset_digest}")"

current_version="$(sed -n 's/^  rimeWanxiangVersion = "\(.*\)";$/\1/p' "${target_file}" | head -n1)"
current_asset_name="$(sed -n 's/^  rimeWanxiangAssetName = "\(.*\)";$/\1/p' "${target_file}" | head -n1)"
current_wanxiang_hash="$(sed -n 's/^  rimeWanxiangZipHash = "\(sha256-[^"]*\)";$/\1/p' "${target_file}" | head -n1)"
current_gram_hash="$(sed -n 's/^  rimeWanxiangGramHash = "\(sha256-[^"]*\)";$/\1/p' "${target_file}" | head -n1)"

if [[ "${current_version}" == "${version}" && "${current_asset_name}" == "${wanxiang_asset_name}" && "${current_wanxiang_hash}" == "${wanxiang_hash}" && "${current_gram_hash}" == "${gram_hash}" ]]; then
  echo "rime-wanxiang is already up to date (${version})"
  exit 0
fi

sed -Ei 's|^  rimeWanxiangVersion = "[^"]+";$|  rimeWanxiangVersion = "'"${version}"'";|' "${target_file}"
sed -Ei 's|^  rimeWanxiangAssetName = "[^"]+";$|  rimeWanxiangAssetName = "'"${wanxiang_asset_name}"'";|' "${target_file}"
sed -Ei 's|^  rimeWanxiangZipHash = "sha256-[^"]+";$|  rimeWanxiangZipHash = "'"${wanxiang_hash}"'";|' "${target_file}"
sed -Ei 's|^  rimeWanxiangGramHash = "sha256-[^"]+";$|  rimeWanxiangGramHash = "'"${gram_hash}"'";|' "${target_file}"

echo "updated ${target_file}"
echo "  version:       ${current_version:-unknown} -> ${version}"
echo "  asset name:    ${current_asset_name:-unknown} -> ${wanxiang_asset_name}"
echo "  wanxiang hash: ${current_wanxiang_hash:-unknown} -> ${wanxiang_hash}"
echo "  gram hash:     ${current_gram_hash:-unknown} -> ${gram_hash}"
echo "  asset:         ${wanxiang_asset_url}"
echo "  gram:          ${gram_asset_url}"
