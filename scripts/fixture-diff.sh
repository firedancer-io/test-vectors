#!/usr/bin/env bash
#
# Render the .fix changes between two commits as a decoded text diff. Run
# scripts/setup-fix-diff.sh first. Writes to <out_dir>:
#
#   fixture.diff  decoded diff of the first MAX_FILES changed fixtures
#   report.md     per-directory summary plus the diff, truncated to fit in a
#                 PR comment (GitHub caps comments at 65536 characters)
#
# usage: [MAX_FILES=500] [RUN_URL=<url>] [COMMIT_SHA=<sha>] \
#          scripts/fixture-diff.sh <base> <head> <out_dir>
#
# COMMIT_SHA names the commit the report describes when <head> isn't it, e.g.
# the PR head when CI diffs GitHub's temporary merge commit.

set -euo pipefail

base="$1"
head="$2"
out_dir="$3"
max_files="${MAX_FILES:-500}"
max_report_bytes=60000
commit="${COMMIT_SHA:-$(git rev-parse "$head")}"
protosol_version=$(< "$(git rev-parse --show-toplevel)/scripts/PROTOSOL_VERSION")

mkdir -p "$out_dir"
diff_file="$out_dir/fixture.diff"
report="$out_dir/report.md"

# Fixture names hash the input, so a regenerated input shows up as a rename.
mapfile -t changes < <(git diff --name-status -M "$base" "$head" -- '*.fix')
total="${#changes[@]}"

# Pathspec for the first max_files changes, both sides of each rename.
paths=()
for change in "${changes[@]:0:max_files}"; do
  IFS=$'\t' read -r -a fields <<< "$change"
  paths+=("${fields[@]:1}")
done

: > "$diff_file"
if (( ${#paths[@]} )); then
  git diff --no-color -M "$base" "$head" -- "${paths[@]}" > "$diff_file"
fi

{
  echo "<!-- fixture-diff -->"
  echo "### Fixture diff"
  echo
  # A bare full SHA renders as a commit link in GitHub comments.
  echo "Commit $commit, decoded with protosol $protosol_version."
  echo
  if (( total == 0 )); then
    echo "No fixture changes."
    exit 0
  fi
  echo "$total fixture(s) changed."
  echo
  echo "| Directory | Added | Modified | Deleted | Renamed |"
  echo "| --- | --: | --: | --: | --: |"
  printf '%s\n' "${changes[@]}" | awk -F'\t' '
    {
      path = $NF
      sub(/\/fixtures/, "", path)
      sub(/\/[^\/]*$/, "", path)
      dirs[path]
      count[path, substr($1, 1, 1)]++
    }
    END {
      for (d in dirs)
        printf "| `%s` | %d | %d | %d | %d |\n", d, count[d, "A"], count[d, "M"], count[d, "D"], count[d, "R"]
    }' | sort
  echo
} > "$report"

notes=()
if (( total > max_files )); then
  notes+=("Decoded the first $max_files of $total changed fixtures.")
fi

# Leave room for the fences and notes around the diff.
budget=$(( max_report_bytes - $(wc -c < "$report") - 1000 ))
if (( $(wc -c < "$diff_file") > budget )); then
  # Cut on a line boundary.
  diff_text=$(head -c "$budget" "$diff_file" | sed '$d')
  notes+=("Diff truncated to fit in a comment.")
else
  diff_text=$(< "$diff_file")
fi
if (( ${#notes[@]} )) && [[ -n "${RUN_URL:-}" ]]; then
  notes+=("Full diff: [workflow run]($RUN_URL), artifact \`fixture-diff\`.")
fi

{
  if [[ -n "$diff_text" ]]; then
    echo '```diff'
    printf '%s\n' "$diff_text"
    echo '```'
  fi
  if (( ${#notes[@]} )); then
    echo
    echo "_${notes[*]}_"
  fi
} >> "$report"
