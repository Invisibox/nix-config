#!/usr/bin/env bash
set -euo pipefail

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
target_file="${repo_root}/home-manager/zsh/zsh.nix"

if [[ ! -f "${target_file}" ]]; then
  echo "error: target file not found: ${target_file}" >&2
  exit 1
fi

for cmd in curl jq nix awk sed mktemp cp mv; do
  if ! command -v "${cmd}" >/dev/null 2>&1; then
    echo "error: missing command: ${cmd}" >&2
    exit 1
  fi
done

plugins=(
  "zsh-syntax-highlighting|zsh-users|zsh-syntax-highlighting"
  "zsh-autosuggestions|zsh-users|zsh-autosuggestions"
  "fzf-tab-completion|lincheney|fzf-tab-completion"
  "zsh-smartcache|QuarticCat|zsh-smartcache"
  "zsh-no-ps2|romkatv|zsh-no-ps2"
)

if (( $# > 0 )); then
  requested_plugins=("$@")
  filtered_plugins=()

  for requested in "${requested_plugins[@]}"; do
    found=0
    for entry in "${plugins[@]}"; do
      IFS='|' read -r plugin_name _ _ <<<"${entry}"
      if [[ "${requested}" == "${plugin_name}" ]]; then
        filtered_plugins+=("${entry}")
        found=1
        break
      fi
    done

    if (( found == 0 )); then
      echo "error: unknown plugin: ${requested}" >&2
      echo "known plugins:" >&2
      for entry in "${plugins[@]}"; do
        IFS='|' read -r plugin_name _ _ <<<"${entry}"
        echo "  - ${plugin_name}" >&2
      done
      exit 1
    fi
  done

  plugins=("${filtered_plugins[@]}")
fi

read_current_values() {
  local plugin_name="$1"
  local file_path="$2"

  awk -v plugin_name="${plugin_name}" '
    BEGIN {
      in_block = 0
      in_plugin_body = 0
      rev = ""
      hash = ""
    }

    $0 ~ "^[[:space:]]*" plugin_name " = let[[:space:]]*$" {
      in_block = 1
    }

    in_block && $0 ~ "^[[:space:]]*mkZshPlugin[[:space:]]+name[[:space:]]*\\{" {
      in_plugin_body = 1
    }

    in_block && rev == "" && match($0, /rev = "([^"]+)";/, m) {
      rev = m[1]
    }

    in_block && hash == "" && match($0, /hash = "(sha256-[^"]+)";/, m) {
      hash = m[1]
    }

    in_block && rev != "" && hash != "" {
      print rev "|" hash
      exit
    }

    in_block && in_plugin_body && $0 ~ "^[[:space:]]{0,4}\\};[[:space:]]*$" {
      in_block = 0
      in_plugin_body = 0
    }
  ' "${file_path}"
}

replace_plugin_values() {
  local plugin_name="$1"
  local new_rev="$2"
  local new_hash="$3"
  local source_file="$4"
  local output_file="$5"

  awk -v plugin_name="${plugin_name}" -v new_rev="${new_rev}" -v new_hash="${new_hash}" '
    BEGIN {
      in_block = 0
      in_plugin_body = 0
      rev_updated = 0
      hash_updated = 0
    }

    $0 ~ "^[[:space:]]*" plugin_name " = let[[:space:]]*$" {
      in_block = 1
    }

    in_block && $0 ~ "^[[:space:]]*mkZshPlugin[[:space:]]+name[[:space:]]*\\{" {
      in_plugin_body = 1
    }

    in_block && rev_updated == 0 && $0 ~ "^[[:space:]]*rev = \"" {
      sub(/rev = "[^"]+";/, "rev = \"" new_rev "\";")
      rev_updated = 1
    }

    in_block && hash_updated == 0 && $0 ~ "^[[:space:]]*hash = \"sha256-" {
      sub(/hash = "sha256-[^"]+";/, "hash = \"" new_hash "\";")
      hash_updated = 1
    }

    { print }

    in_block && in_plugin_body && $0 ~ "^[[:space:]]{0,4}\\};[[:space:]]*$" {
      in_block = 0
      in_plugin_body = 0
    }

    END {
      if (rev_updated == 0 || hash_updated == 0) {
        exit 2
      }
    }
  ' "${source_file}" > "${output_file}"
}

github_headers=(-H "Accept: application/vnd.github+json" -H "X-GitHub-Api-Version: 2022-11-28")
if [[ -n "${GITHUB_TOKEN:-}" ]]; then
  github_headers+=(-H "Authorization: Bearer ${GITHUB_TOKEN}")
fi

working_file="$(mktemp)"
next_file="$(mktemp)"
trap 'rm -f "${working_file}" "${next_file}"' EXIT
cp "${target_file}" "${working_file}"

updated_count=0

for entry in "${plugins[@]}"; do
  IFS='|' read -r plugin_name owner repo <<<"${entry}"
  api_url="https://api.github.com/repos/${owner}/${repo}/commits?per_page=1"

  latest_rev="$(
    curl -fsSL "${github_headers[@]}" "${api_url}" \
      | jq -r '.[0].sha // empty'
  )"

  if [[ -z "${latest_rev}" ]]; then
    echo "error: unable to read latest revision for ${owner}/${repo}" >&2
    exit 1
  fi

  archive_url="https://github.com/${owner}/${repo}/archive/${latest_rev}.tar.gz"
  latest_hash="$(nix store prefetch-file --json --unpack "${archive_url}" | jq -r '.hash // empty')"

  if [[ -z "${latest_hash}" ]]; then
    echo "error: unable to prefetch hash for ${owner}/${repo}@${latest_rev}" >&2
    exit 1
  fi

  current_values="$(read_current_values "${plugin_name}" "${working_file}")"
  if [[ -z "${current_values}" ]]; then
    echo "error: unable to locate rev/hash for plugin block: ${plugin_name}" >&2
    exit 1
  fi

  IFS='|' read -r current_rev current_hash <<<"${current_values}"

  if [[ "${current_rev}" == "${latest_rev}" && "${current_hash}" == "${latest_hash}" ]]; then
    echo "${plugin_name} is already up to date (${latest_rev})"
    continue
  fi

  if ! replace_plugin_values "${plugin_name}" "${latest_rev}" "${latest_hash}" "${working_file}" "${next_file}"; then
    echo "error: failed to update plugin block: ${plugin_name}" >&2
    exit 1
  fi

  mv "${next_file}" "${working_file}"
  : > "${next_file}"
  updated_count=$((updated_count + 1))

  echo "updated ${plugin_name}"
  echo "  rev:  ${current_rev} -> ${latest_rev}"
  echo "  hash: ${current_hash} -> ${latest_hash}"
done

if (( updated_count == 0 )); then
  echo "zsh plugins are already up to date"
  exit 0
fi

cp "${working_file}" "${target_file}"
echo "updated ${target_file} (${updated_count} plugin(s))"
