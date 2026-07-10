## 1. Rust structural harness

- [x] 1.1 **S02-RH-W01** Add failing Rust tests for canonical roster reproduction, forbidden root-set fields, domain/reset vectors, continuity keys, and blocked outcome classification; then implement the minimal library and CLI. Verification: `cargo test --manifest-path reference/rust/Cargo.toml --all-targets`.

## 2. Go structural harness and BSB22 parser

- [ ] 2.1 **S02-RH-W02** Add failing Go tests for an independent deterministic-CBOR encoder, roster/root/domain/continuity agreement, exact BSB22 proof/VK offsets, scalar modulus rejection, and parser non-claims; then implement the commands. Verification: `go test ./...` from `reference/go`.

## 3. Shared cross-language fixtures

- [ ] 3.1 **S02-RH-W03** Publish bounded structural fixtures and expected reports, compare parsed Rust and Go outputs byte-for-byte, and include mutation/reset/replay vectors. Verification: `powershell -NoProfile -File scripts/compare-reference-harness.ps1`.

## 4. Scrapling observation adapters

- [ ] 4.1 **S02-RH-W04** Add failing Python `unittest` cases for Midnight RPC and Mithril response normalization, provenance, trust-label rejection, and captured fixtures; then implement Scrapling-only transport and the observation CLI. Verification: `.\.venv-scrapling\Scripts\python.exe -m unittest discover -s reference/observers/tests -v`.

## 5. Combined verification and documentation

- [ ] 5.1 **S02-RH-W05** Add one noninteractive verifier that runs Rust, Go, Python, cross-language, roster, and strict OpenSpec checks and emits `structural-pass` with deployment outcome `blocked`. Document commands and gate limits in `reference/README.md`. Verification: `powershell -NoProfile -File scripts/verify-reference-harness.ps1`.

## 6. Independent review

- [ ] 6.1 **S02-RH-W06** Run proof-systems, consensus, and operator readers over the implementation and evidence; resolve every blocking and major finding, record output hashes in `review.md`, and rerun all verification. Verification: `npm run openspec:validate` plus `git diff --check` and the combined verifier.
