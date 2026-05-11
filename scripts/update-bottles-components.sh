#!/usr/bin/env bash
set -euo pipefail

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
target_file="${repo_root}/modules/apps/bottles/default.nix"
components_ref="${BOTTLES_COMPONENTS_REF:-main}"
components_index="${BOTTLES_COMPONENTS_INDEX:-index.yml}"
components_base="https://raw.githubusercontent.com/bottlesdevs/components/${components_ref}"
index_url="${components_base}/${components_index}"

if [[ ! -f "${target_file}" ]]; then
  echo "error: target file not found: ${target_file}" >&2
  exit 1
fi

for cmd in awk curl jq nix sed; do
  if ! command -v "${cmd}" >/dev/null 2>&1; then
    echo "error: missing command: ${cmd}" >&2
    exit 1
  fi
done

github_headers=(-H "Accept: application/vnd.github.raw")
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

select_component() {
  local category="$1"
  local subcategory="$2"
  local prefix="$3"

  awk \
    -v wanted_category="${category}" \
    -v wanted_subcategory="${subcategory}" \
    -v wanted_prefix="${prefix}" '
      function reset_component(component_name) {
        name = component_name
        category_ok = 0
        channel_ok = 0
        subcategory_ok = (wanted_subcategory == "")
        prefix_ok = (wanted_prefix == "" || index(name, wanted_prefix) == 1)
      }

      function flush_component() {
        if (name != "" && category_ok && channel_ok && subcategory_ok && prefix_ok) {
          print name
          found = 1
          exit
        }
      }

      BEGIN {
        name = ""
        found = 0
      }

      /^[^#[:space:]][^:]*:$/ {
        flush_component()
        component_name = $0
        sub(/:$/, "", component_name)
        reset_component(component_name)
        next
      }

      name != "" && $1 == "Category:" && $2 == wanted_category {
        category_ok = 1
        next
      }

      name != "" && $1 == "Sub-category:" && $2 == wanted_subcategory {
        subcategory_ok = 1
        next
      }

      name != "" && $1 == "Channel:" && $2 == "stable" {
        channel_ok = 1
        next
      }

      END {
        if (!found) {
          flush_component()
        }
      }
    ' <<<"${index_yaml}"
}

manifest_value() {
  local key="$1"
  sed -n \
    -e "s/^[[:space:]]*-[[:space:]]*${key}:[[:space:]]*//p" \
    -e "s/^[[:space:]]*${key}:[[:space:]]*//p" \
    <<<"${manifest_yaml}" | head -n1
}

source_dir_from_file_name() {
  local file_name="$1"
  local source_dir="${file_name}"

  source_dir="${source_dir%.tar.gz}"
  source_dir="${source_dir%.tar.xz}"
  source_dir="${source_dir%.tgz}"
  source_dir="${source_dir%.zip}"

  printf '%s\n' "${source_dir}"
}

read_info_value() {
  local attr="$1"
  local key="$2"

  sed -n "/^  ${attr} = {$/,/^  };$/s/^    ${key} = \"\\(.*\\)\";$/\\1/p" "${target_file}" | head -n1
}

update_info_block() {
  local attr="$1"
  local name="$2"
  local url="$3"
  local hash="$4"
  local source_dir="$5"

  sed -Ei "/^  ${attr} = \\{$/,/^  \\};$/s|^    name = \".*\";$|    name = \"${name}\";|" "${target_file}"
  sed -Ei "/^  ${attr} = \\{$/,/^  \\};$/s|^    url = \".*\";$|    url = \"${url}\";|" "${target_file}"
  sed -Ei "/^  ${attr} = \\{$/,/^  \\};$/s|^    hash = \"sha256-[^\"]+\";$|    hash = \"${hash}\";|" "${target_file}"
  sed -Ei "/^  ${attr} = \\{$/,/^  \\};$/s|^    sourceDir = \".*\";$|    sourceDir = \"${source_dir}\";|" "${target_file}"
}

update_component() {
  local attr="$1"
  local category="$2"
  local subcategory="$3"
  local prefix="$4"
  local manifest_dir="$5"

  local name
  name="$(select_component "${category}" "${subcategory}" "${prefix}")"
  if [[ -z "${name}" ]]; then
    echo "error: unable to find latest stable component for ${attr}" >&2
    exit 1
  fi

  manifest_yaml="$(curl_fetch "${github_headers[@]}" "${components_base}/${manifest_dir}/${name}.yml")"

  local file_name url source_dir hash
  file_name="$(manifest_value "file_name")"
  url="$(manifest_value "url")"
  source_dir="$(source_dir_from_file_name "${file_name}")"

  if [[ -z "${file_name}" || -z "${url}" ]]; then
    echo "error: manifest missing file_name or url: ${manifest_dir}/${name}.yml" >&2
    exit 1
  fi

  hash="$(nix store prefetch-file --json --unpack "${url}" | jq -r '.hash')"
  if [[ -z "${hash}" || "${hash}" == "null" ]]; then
    echo "error: unable to determine hash for ${url}" >&2
    exit 1
  fi

  local current_name current_url current_hash current_source_dir
  current_name="$(read_info_value "${attr}" "name")"
  current_url="$(read_info_value "${attr}" "url")"
  current_hash="$(read_info_value "${attr}" "hash")"
  current_source_dir="$(read_info_value "${attr}" "sourceDir")"

  if [[ "${current_name}" == "${name}" \
    && "${current_url}" == "${url}" \
    && "${current_hash}" == "${hash}" \
    && "${current_source_dir}" == "${source_dir}" ]]; then
    echo "${attr} is already up to date (${name})"
    return
  fi

  update_info_block "${attr}" "${name}" "${url}" "${hash}" "${source_dir}"

  echo "updated ${attr}"
  echo "  name:      ${current_name:-unknown} -> ${name}"
  echo "  sourceDir: ${current_source_dir:-unknown} -> ${source_dir}"
  echo "  hash:      ${current_hash:-unknown} -> ${hash}"
  echo "  url:       ${url}"
}

index_yaml="$(curl_fetch "${github_headers[@]}" "${index_url}")"

update_component "runtimeComponentInfo" "runtimes" "" "runtime-" "runtimes"
update_component "dxvkComponentInfo" "dxvk" "" "dxvk-" "dxvk"
update_component "vkd3dComponentInfo" "vkd3d" "" "vkd3d-proton-" "vkd3d"
update_component "nvapiComponentInfo" "nvapi" "" "dxvk-nvapi-" "nvapi"
update_component "latencyflexComponentInfo" "latencyflex" "" "latencyflex-" "latencyflex"
update_component "caffeRunnerInfo" "runners" "wine" "caffe-" "runners/wine"
update_component "sodaRunnerInfo" "runners" "wine" "soda-" "runners/wine"
