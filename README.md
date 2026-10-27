# Overview

This repository contains solana-conformance test vectors.
Each file is one Protobuf serialized test input.

## Type mappings

| Path        | Type                                                                                         |
|-----------------|-----------------------------------------------------------------------------------------------------|
|`instr/inputs/**/*.bin` | `org.solana.sealevel.v1.InstrContext`|
| `instr/fixtures/**/*.bin` | `org.solana.sealevel.v1.InstrFixture` |


# Fuzz failure debugging workflow

1. Any new mismatches are added to `instr/inputs/fuzz-mismatches`
2. Once mismatches are debugged, create a fixture out of them (see [solana-conformance]((https://github.com/firedancer-io/solana-conformance)) to see how its done)
3. Add the fixture to `instr/fixtures/<program>` depending on which native program the mismatch came from

CI will regress against any fixtures in this directory and produce a coverage report on every PR.

# Fixture diffs

`.fix` files are binary protobufs. To render them as text in `git diff`, `git show` and `git log -p`, run this once per clone (needs `protoc`, e.g. `apt install protobuf-compiler`):

```sh
scripts/setup-fix-diff.sh
```

Pull requests that change fixtures get the same decoded diff as a comment. Decoding uses the protosol release pinned in `scripts/PROTOSOL_VERSION`; bump it when regenerating fixtures for a new protosol version.

# External links

[solfuzz](https://github.com/firedancer-io/solfuzz)
