#!/usr/bin/env bash
#
# Git textconv driver that decodes a .fix fixture to protobuf text format.
#
#   PROTOSOL_PROTO_DIR=/path/to/protosol/proto scripts/fix-textconv.sh <file>
#
# Git hands textconv a temp copy of the blob, so the message type comes from
# the fixture's metadata.fn_entrypoint (always the first field) rather than
# the path. Undecodable input falls back to --decode_raw so a single bad
# fixture never aborts a whole `git diff`. See scripts/setup-fix-diff.sh.

set -euo pipefail

file="$1"
proto_dir="${PROTOSOL_PROTO_DIR:?not set, run scripts/setup-fix-diff.sh}"

entrypoint=$(head -c 128 -- "$file" | grep -aom1 'sol_compat_[a-z0-9_]*' || true)

case "$entrypoint" in
  sol_compat_block_execute_v1)        proto=block.proto;            msg=BlockFixture ;;
  sol_compat_elf_loader_v1)           proto=elf.proto;              msg=ELFLoaderFixture ;;
  sol_compat_gossip_decode_v1)        proto=gossip.proto;           msg=GossipFixture ;;
  sol_compat_instr_execute_v1)        proto=instr.proto;            msg=InstrFixture ;;
  sol_compat_shred_parse_v1)          proto=shred.proto;            msg=ShredParseFixture ;;
  sol_compat_txn_cost_v1)             proto=cost.proto;             msg=CostFixture ;;
  sol_compat_txn_execute_v1)          proto=txn.proto;              msg=TxnFixture ;;
  sol_compat_vm_serialize_execute_v1) proto=vm_serialization.proto; msg=VMSerializationFixture ;;
  sol_compat_vm_syscall_execute_v1)   proto=vm.proto;               msg=SyscallFixture ;;
  *)                                  proto=;                       msg= ;;
esac

if [[ -n "$msg" ]] &&
  protoc -I "$proto_dir" --decode="org.solana.sealevel.v1.$msg" "$proto" < "$file"; then
  exit 0
fi

echo "# fix-textconv: cannot decode as '${msg:-unknown entrypoint ${entrypoint:-<none>}}', raw decode follows"
protoc --decode_raw < "$file" ||
  echo "# fix-textconv: not a protobuf ($(wc -c < "$file") bytes, sha256 $(sha256sum < "$file" | cut -d' ' -f1))"
