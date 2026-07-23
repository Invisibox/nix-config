#!/usr/bin/env bash
set -euo pipefail

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
target_file="${repo_root}/modules/apps/baidunetdisk/package.nix"
official_api_url="https://pan.baidu.com/disk/cmsdata?do=client&adCode=1"

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

if [[ -z "${official_version}" || -z "${official_url}" ]]; then
  echo "error: unable to read official release metadata" >&2
  exit 1
fi

if [[ "${official_url}" != https://*.rpm ]]; then
  echo "error: expected an official RPM source" >&2
  exit 1
fi

if [[ "${current_version}" == "${official_version}" && "${current_url}" == "${official_url}" ]]; then
  echo "baidunetdisk is already current (${official_version})"
  exit 0
fi

if [[ "$(printf '%s\n%s\n' "${current_version}" "${official_version}" | sort -V | tail -n1)" == "${current_version}" ]]; then
  echo "no update: local version (${current_version}) is newer than official (${official_version})"
  exit 0
fi

hash="$(nix store prefetch-file --json "${official_url}" | jq -r '.hash')"

sed -Ei 's|^  version = "[^"]+";$|  version = "'"${official_version}"'";|' "${target_file}"
sed -Ei 's|^    url = "[^"]+";$|    url = "'"${official_url}"'";|' "${target_file}"
sed -Ei 's|^    hash = "sha256-[^"]+";$|    hash = "'"${hash}"'";|' "${target_file}"

updated_version="$(sed -n 's/^  version = "\(.*\)";$/\1/p' "${target_file}" | head -n1)"
updated_url="$(sed -n 's/^    url = "\(.*\)";$/\1/p' "${target_file}" | head -n1)"
updated_hash="$(sed -n 's/^    hash = "\(sha256-[^"]*\)";$/\1/p' "${target_file}" | head -n1)"

if [[ "${updated_version}" != "${official_version}" || "${updated_url}" != "${official_url}" || "${updated_hash}" != "${hash}" ]]; then
  echo "error: failed to update version, URL, or hash in ${target_file}" >&2
  exit 1
fi

echo "updated ${target_file} to ${official_version}"
