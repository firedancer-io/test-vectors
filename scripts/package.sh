#!/usr/bin/env bash
#
# Package each top-level fixture folder into a reproducible .tar.gz under out/
# and print a SHA256SUMS table for the release notes (needs GNU tar).
# Progress is written to stderr so stdout stays usable as the release notes.
# Run from the repo root.

set -euo pipefail

OUT="out"
mkdir -p "$OUT"

package() {
  local f="$1"
  echo "==> $f ($(find "$f" -type f | wc -l) files)" >&2
  SECONDS=0
  tar --sort=name --mtime='@0' --owner=0 --group=0 --numeric-owner \
      --mode='u=rwX,go=rX' --format=gnu -cf - "$f" | gzip -n -9 > "$OUT/$f.tar.gz"
  echo "    $f.tar.gz  $(du -h "$OUT/$f.tar.gz" | cut -f1)  ${SECONDS}s" >&2
  echo "| \`$f.tar.gz\` | \`$(sha256sum "$OUT/$f.tar.gz" | cut -d' ' -f1)\` |"
}

echo "## Fixture archives"
echo
echo "| Archive | SHA-256 |"
echo "| --- | --- |"
for f in block cost elf_loader gossip instr shred syscall txn vm_serialization; do
  package "$f"
done
