#!/usr/bin/env bash
set -euo pipefail

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
target_file="${repo_root}/modules/apps/baidunetdisk/package.nix"
official_api_url="https://pan.baidu.com/disk/cmsdata?do=client&adCode=1"
flathub_api_url="https://flathub.org/api/v2/appstream/com.baidu.NetDisk"
flathub_manifest_url="https://raw.githubusercontent.com/flathub/com.baidu.NetDisk/master/com.baidu.NetDisk.yaml"

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

current_version="$(sed -n 's/^  version = "\(.*\)";$/\1/p' "${target_file}" | head -n1)"
current_url="$(sed -n 's/^    url = "\(.*\)";$/\1/p' "${target_file}" | head -n1)"
current_hash="$(sed -n 's/^    hash = "\(sha256-[^"]*\)";$/\1/p' "${target_file}" | head -n1)"

if [[ -z "${current_version}" || -z "${current_url}" || -z "${current_hash}" ]]; then
  echo "error: unable to locate the current version, URL, or hash in ${target_file}" >&2
  exit 1
fi

official_json="$(curl -fsSL "${official_api_url}")"
official_info="$(jq -r '
  .linux as $linux
  | ($linux.version | capture("V(?<version>[0-9]+(\\.[0-9]+)+)").version) as $version
  | [$version, $linux.url]
  | @tsv
' <<<"${official_json}")"
IFS=$'\t' read -r official_version official_url <<<"${official_info}"

flathub_json="$(curl -fsSL "${flathub_api_url}")"
if [[ "$(jq -r '.is_eol' <<<"${flathub_json}")" == "true" ]]; then
  echo "error: Flathub currently marks com.baidu.NetDisk as EOL; refusing to update" >&2
  exit 1
fi
flathub_version="$(jq -r '.releases[0].version // empty' <<<"${flathub_json}")"

manifest="$(curl -fsSL "${flathub_manifest_url}")"
manifest_url="$(sed -n 's|^        url: \(https://.*\.rpm\)$|\1|p' <<<"${manifest}" | head -n1)"
manifest_sha256="$(sed -n 's/^        sha256: \([0-9a-f]\{64\}\)$/\1/p' <<<"${manifest}" | head -n1)"
manifest_version="$(sed -n 's|.*baidunetdisk-\([0-9][0-9.]*\)\.x86_64\.rpm.*|\1|p' <<<"${manifest}" | head -n1)"

if [[ -z "${official_version}" || -z "${official_url}" || -z "${flathub_version}" || -z "${manifest_url}" || -z "${manifest_sha256}" || -z "${manifest_version}" ]]; then
  echo "error: unable to read official or Flathub release metadata" >&2
  exit 1
fi

if [[ "${official_url}" != https://*.rpm || "${manifest_url}" != https://*.rpm ]]; then
  echo "error: expected official and Flathub RPM sources" >&2
  exit 1
fi

# The published Flathub release is the compatibility gate. It prevents this
# script from adopting a vendor release before its FHS runtime has validated it.
if [[ "${flathub_version}" != "${manifest_version}" ]]; then
  echo "error: Flathub's published version (${flathub_version}) differs from its manifest (${manifest_version})" >&2
  exit 1
fi

if [[ "${official_version}" != "${flathub_version}" || "${official_url}" != "${manifest_url}" ]]; then
  echo "no update: official release (${official_version}) is not yet the published Flathub release (${flathub_version})"
  exit 0
fi

if [[ "${current_version}" == "${flathub_version}" && "${current_url}" == "${manifest_url}" ]]; then
  echo "baidunetdisk is already aligned with Flathub (${flathub_version})"
  exit 0
fi

if [[ "$(printf '%s\n%s\n' "${current_version}" "${flathub_version}" | sort -V | tail -n1)" == "${current_version}" ]]; then
  echo "no update: local version (${current_version}) is newer than published Flathub (${flathub_version})"
  exit 0
fi

# This is the only path that downloads the full RPM. Its content must match
# the SHA-256 pinned by Flathub before package.nix is modified.
expected_hash="$(nix hash to-sri --type sha256 "${manifest_sha256}")"
hash="$(nix store prefetch-file --json --expected-hash "${expected_hash}" "${manifest_url}" | jq -r '.hash')"
if [[ "${hash}" != "${expected_hash}" ]]; then
  echo "error: fetched RPM hash does not match Flathub's checksum" >&2
  exit 1
fi

sed -Ei 's|^  version = "[^"]+";$|  version = "'"${flathub_version}"'";|' "${target_file}"
sed -Ei 's|^    url = "[^"]+";$|    url = "'"${manifest_url}"'";|' "${target_file}"
sed -Ei 's|^    hash = "sha256-[^"]+";$|    hash = "'"${hash}"'";|' "${target_file}"

updated_version="$(sed -n 's/^  version = "\(.*\)";$/\1/p' "${target_file}" | head -n1)"
updated_url="$(sed -n 's/^    url = "\(.*\)";$/\1/p' "${target_file}" | head -n1)"
updated_hash="$(sed -n 's/^    hash = "\(sha256-[^"]*\)";$/\1/p' "${target_file}" | head -n1)"

if [[ "${updated_version}" != "${flathub_version}" || "${updated_url}" != "${manifest_url}" || "${updated_hash}" != "${hash}" ]]; then
  echo "error: failed to update version, URL, or hash in ${target_file}" >&2
  exit 1
fi

echo "updated ${target_file} to Flathub-validated ${flathub_version}"
