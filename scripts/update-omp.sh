#!/usr/bin/env bash
set -euo pipefail

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
target_file="${repo_root}/modules/apps/omp/package.nix"
api_url="https://api.github.com/repos/can1357/oh-my-pi/releases/latest"
asset_name="omp-linux-x64"

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

release_json="$(curl -fsSL "${api_url}")"
tag_name="$(jq -r '.tag_name // empty' <<<"${release_json}")"
if [[ -z "${tag_name}" ]]; then
  echo "error: unable to read latest release tag from ${api_url}" >&2
  exit 1
fi

version="${tag_name#v}"
asset_info="$(jq -r --arg name "${asset_name}" '
  .assets[]
  | select(.name == $name)
  | [.browser_download_url, (.digest // "")]
  | @tsv
' <<<"${release_json}")"

if [[ -z "${asset_info}" ]]; then
  echo "error: unable to find ${asset_name} in release ${tag_name}" >&2
  exit 1
fi

IFS=$'\t' read -r asset_url asset_digest <<<"${asset_info}"

hash=""
if [[ "${asset_digest}" =~ ^sha256:([0-9A-Fa-f]{64})$ ]]; then
  hash="$(nix hash convert --hash-algo sha256 --to sri "${BASH_REMATCH[1]}")"
fi

if [[ -z "${hash}" || "${hash}" == "null" ]]; then
  hash="$(nix store prefetch-file --json "${asset_url}" | jq -r '.hash')"
fi

if [[ -z "${hash}" || "${hash}" == "null" ]]; then
  echo "error: unable to determine hash for ${asset_url}" >&2
  exit 1
fi

current_version="$(sed -n 's/^  version = "\(.*\)";$/\1/p' "${target_file}" | head -n1)"
current_hash="$(sed -n 's/^      hash = "\(sha256-[^"]*\)";$/\1/p' "${target_file}" | head -n1)"

if [[ -z "${current_version}" || -z "${current_hash}" ]]; then
  echo "error: unable to locate current version/hash in ${target_file}" >&2
  exit 1
fi

if [[ "${current_version}" == "${version}" && "${current_hash}" == "${hash}" ]]; then
  echo "omp is already up to date (${version})"
  exit 0
fi

sed -Ei 's|^  version = "[^"]+";$|  version = "'"${version}"'";|' "${target_file}"
sed -Ei 's|^      hash = "sha256-[^"]+";$|      hash = "'"${hash}"'";|' "${target_file}"

echo "updated ${target_file}"
echo "  version: ${current_version} -> ${version}"
echo "  hash:    ${current_hash} -> ${hash}"
echo "  asset:   ${asset_url}"
