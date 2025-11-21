#!/usr/bin/env bash
# clean_caches.sh - Remove cache/output folders using a shared path list

set -euo pipefail

dry_run=0
if [[ "${1:-}" == "-n" || "${1:-}" == "--dry-run" ]]; then
  dry_run=1
fi

script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
repo_root="$(cd "$script_dir/../.." && pwd)"
paths_file="$script_dir/paths.txt"

if [[ ! -f "$paths_file" ]]; then
  echo "Paths file not found: $paths_file" >&2
  exit 1
fi

shopt -s nullglob dotglob

targets=()
while IFS= read -r line; do
  # trim leading/trailing whitespace
  line="${line#"${line%%[![:space:]]*}"}"
  line="${line%"${line##*[![:space:]]}"}"
  [[ -z "$line" || "${line:0:1}" == "#" ]] && continue

  rel="$line"
  path="$repo_root/$rel"

  if [[ "$rel" == *'*'* || "$rel" == *'?'* || "$rel" == *'['* ]]; then
    for match in $path; do
      targets+=("$match")
    done
  else
    if [[ -e "$path" ]]; then
      targets+=("$path")
    fi
  fi
done < "$paths_file"

echo "Repo root: $repo_root"
echo "Will delete these paths if present:"
if [[ ${#targets[@]} -eq 0 ]]; then
  echo "  (none)"
else
  for t in "${targets[@]}"; do
    echo "  - $t"
  done
fi
[[ $dry_run -eq 1 ]] && echo "(dry run - nothing will be deleted)"

if [[ ${#targets[@]} -eq 0 || $dry_run -eq 1 ]]; then
  echo "Dry run complete."
  exit 0
fi

for t in "${targets[@]}"; do
  if rm -rf -- "$t"; then
    echo "Deleted: $t"
  else
    echo "Failed to delete: $t" >&2
  fi
done

echo "Cache clean complete."
