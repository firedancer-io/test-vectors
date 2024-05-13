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

# Decoding fixtures

Refer to [solana-conformance](https://github.com/firedancer-io/solana-conformance). Use `create-fixture` with desired inputs to create human-readable fixtures from instruction context messages, using a Solana target to generate instruction effects.

# External links
[solana-conformance](https://github.com/firedancer-io/solana-conformance)

[solfuzz](https://github.com/firedancer-io/solfuzz)
