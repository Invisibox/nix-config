#!/usr/bin/env bash
set -euo pipefail

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
target_file="${repo_root}/modules/apps/lobehub/default.nix"
api_url="https://api.github.com/repos/lobehub/lobehub/releases/latest"

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

release_json="$(curl -fsSL "${api_url}")"

tag_name="$(jq -r '.tag_name // empty' <<<"${release_json}")"
if [[ -z "${tag_name}" ]]; then
  echo "error: unable to read latest release tag from ${api_url}" >&2
  exit 1
fi

version="${tag_name#v}"

asset_url="$(jq -r --arg v "${version}" '
  (
    .assets[]
    | select(.name == ("LobeHub-" + $v + ".AppImage"))
    | .browser_download_url
  ) // empty
' <<<"${release_json}")"

if [[ -z "${asset_url}" ]]; then
  asset_url="$(jq -r '
    (
      .assets[]
      | select(.name | test("(?i)\\.AppImage$"))
      | .browser_download_url
    ) // empty
  ' <<<"${release_json}" | head -n1)"
fi

if [[ -z "${asset_url}" ]]; then
  echo "error: unable to find AppImage asset in latest release ${tag_name}" >&2
  exit 1
fi

hash="$(nix store prefetch-file --json "${asset_url}" | jq -r '.hash')"
if [[ -z "${hash}" || "${hash}" == "null" ]]; then
  echo "error: unable to prefetch hash for ${asset_url}" >&2
  exit 1
fi

current_version="$(sed -n 's/^  version = "\(.*\)";$/\1/p' "${target_file}" | head -n1)"
current_hash="$(sed -n 's/^    hash = "\(sha256-[^"]*\)";$/\1/p' "${target_file}" | head -n1)"

if [[ "${current_version}" == "${version}" && "${current_hash}" == "${hash}" ]]; then
  echo "lobehub is already up to date (${version})"
  exit 0
fi

sed -Ei 's/^  version = "[^"]+";$/  version = "'"${version}"'";/' "${target_file}"
sed -Ei 's/^    hash = "sha256-[^"]+";$/    hash = "'"${hash}"'";/' "${target_file}"

echo "updated ${target_file}"
echo "  version: ${current_version:-unknown} -> ${version}"
echo "  hash:    ${current_hash:-unknown} -> ${hash}"
echo "  asset:   ${asset_url}"
