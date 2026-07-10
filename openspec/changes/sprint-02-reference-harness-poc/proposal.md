## Why

The accepted bridge design now needs executable contracts that independent
implementations can compare before proof circuits or destination operations are
available. The first slice should make byte ownership, domain construction,
replay continuity, outcome classification, and source observation testable
without turning structural evidence into a deployment claim.

## What Changes

- Add Rust and Go reference implementations for the published gate-roster bytes,
  structural-lab deployment-domain derivation, source-event continuity keys, and
  deterministic outcome classification.
- Add a Go BSB22 parser for the fixed 336-byte proof, 672-byte VK, and canonical
  public scalar boundary. This checks the landing ABI but does not prove the
  missing full Halo2/KZG decider.
- Add Scrapling-based, read-only Midnight RPC and Cardano Mithril observation
  adapters with captured fixtures, provenance, and explicit untrusted status.
- Add one cross-language conformance command that compares golden bytes and
  digests and reports a structural-lab result separately from deployment labels.
- Keep `S01-BLOCK-01` through `S01-BLOCK-06` and all source-dependent `CONS-*`
  evidence open. No generated fixture, parser test, or endpoint response closes a
  proof relation, public SCLS, destination execution, or testnet outcome gate.

## Capabilities

### New Capabilities

None.

### Modified Capabilities

- `reference-harness`: Require independently implemented Rust and Go structural
  commands, shared golden vectors, and one reproducible conformance entry point.
- `conformance-testnet`: Distinguish unsigned Scrapling observations and
  structural-lab checks from authenticated source evidence and outcome labels.
- `operations-governance`: Add an explicitly non-activating structural hash
  profile for testing the acyclic root/domain construction and reset isolation.
- `groth16-proof-path`: Add an executable BSB22 byte-layout and scalar parser
  without treating parser conformance as full-decider or Cardano execution proof.

## Impact

The change adds a small Rust workspace, a Go module, Python Scrapling adapters,
versioned fixtures, and PowerShell verification scripts under `reference/` and
`scripts/`. It uses Rust 1.90, Go 1.25.7, Python 3.10+ with Scrapling 0.4.10, and
the already installed Cardano 11.0.1 tools. Compact and proof-server deployment
remain blocked on the current Windows host by the unavailable WSL component and
Docker.
