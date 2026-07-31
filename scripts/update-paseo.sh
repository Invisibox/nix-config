#!/usr/bin/env bash
set -euo pipefail

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
target_file="${repo_root}/modules/apps/paseo/package.nix"
api_url="https://api.github.com/repos/getpaseo/paseo/releases/latest"
asset_prefix="Paseo-"
asset_suffix="-amd64.deb"

if [[ ! -f "${target_file}" ]]; then
  echo "error: target file not found: ${target_file}" >&2
  exit 1
fi

for cmd in curl jq nix sed head; do
  if ! command -v "${cmd}" >/dev/null 2>&1; then
    echo "error: missing command: ${cmd}" >&2
    exit 1
  fi
done

release_json="$(curl -fsSL "${api_url}")"
tag_name="$(jq -r '.tag_name // empty' <<<"${release_json}")"
if [[ -z "${tag_name}" ]]; then
  echo "error: unable to read latest release tag from ${api_url}" >&2
  exit 1
fi

version="${tag_name#v}"
asset_info="$(jq -r --arg prefix "${asset_prefix}" --arg suffix "${asset_suffix}" '
  .assets[]
  | select(.name | startswith($prefix) and endswith($suffix))
  | [.name, .browser_download_url, (.digest // "")]
  | @tsv
' <<<"${release_json}" | head -n1)"

if [[ -z "${asset_info}" ]]; then
  echo "error: unable to find Linux amd64 deb asset in release ${tag_name}" >&2
  exit 1
fi

IFS=$'\t' read -r asset_name asset_url asset_digest <<<"${asset_info}"
expected_asset_name="${asset_prefix}${version}${asset_suffix}"
if [[ "${asset_name}" != "${expected_asset_name}" ]]; then
  echo "error: release asset version does not match release tag: ${asset_name}" >&2
  exit 1
fi

hash=""
if [[ "${asset_digest}" =~ ^sha256:([0-9A-Fa-f]{64})$ ]]; then
  hash="$(nix hash convert --hash-algo sha256 --to sri "${BASH_REMATCH[1]}")"
fi

if [[ -z "${hash}" || "${hash}" == "null" ]]; then
  echo "error: GitHub release did not provide a sha256 digest; refusing to download the package" >&2
  exit 1
fi

current_version="$(sed -n 's/^  version = "\(.*\)";$/\1/p' "${target_file}" | head -n1)"
current_hash="$(sed -n 's/^      hash = "\(sha256-[^"]*\)";$/\1/p' "${target_file}" | head -n1)"

if [[ -z "${current_version}" || -z "${current_hash}" ]]; then
  echo "error: unable to locate current version/hash in ${target_file}" >&2
  exit 1
fi

if [[ "${current_version}" == "${version}" && "${current_hash}" == "${hash}" ]]; then
  echo "paseo is already up to date (${version})"
  exit 0
fi

sed -Ei 's|^  version = "[^"]+";$|  version = "'"${version}"'";|' "${target_file}"
sed -Ei 's|^      hash = "sha256-[^"]+";$|      hash = "'"${hash}"'";|' "${target_file}"

echo "updated ${target_file}"
echo "  version: ${current_version} -> ${version}"
echo "  hash:    ${current_hash} -> ${hash}"
echo "  asset:   ${asset_url}"
