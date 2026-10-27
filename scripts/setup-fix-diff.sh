#!/usr/bin/env bash
#
# Make `git diff`, `git show` and `git log -p` render .fix fixtures as text in
# this clone. Downloads the protosol .proto files pinned in
# scripts/PROTOSOL_VERSION into the git dir and registers
# scripts/fix-textconv.sh as the driver for the `diff=fix` attribute set in
# .gitattributes. Re-run after bumping PROTOSOL_VERSION. Needs curl and protoc.

set -euo pipefail

command -v protoc >/dev/null || { echo "protoc not found (apt install protobuf-compiler)" >&2; exit 1; }

root=$(git rev-parse --show-toplevel)
version=$(< "$root/scripts/PROTOSOL_VERSION")
proto_dir="$(git rev-parse --path-format=absolute --git-common-dir)/protosol-$version"

if [[ ! -d "$proto_dir" ]]; then
  tmp=$(mktemp -d "$proto_dir.XXXXXX")
  trap 'rm -rf "$tmp"' EXIT
  curl -sSfL "https://github.com/firedancer-io/protosol/archive/refs/tags/$version.tar.gz" |
    tar -xz -C "$tmp" --strip-components=2 --wildcards '*/proto/*.proto'
  mv "$tmp" "$proto_dir"
fi

git config diff.fix.textconv "env PROTOSOL_PROTO_DIR='$proto_dir' '$root/scripts/fix-textconv.sh'"
echo "fixture diffs enabled (protosol $version)" >&2
