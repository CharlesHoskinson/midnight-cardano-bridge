## 3. Populate the canonical 25-section bridge design

**Files:** Modify `knowledge_base/bridges/midnight-cardano-recursive-bridge.md`.

**Interface:** Consume all current knowledge-base pages, the program design, and gated source packs. Produce one current-state narrative with exactly 25 numbered top-level sections.

- [x] 3.1 **S01-T03-W01** Preserve existing provenance identifiers and relative source links before restructuring the living design.
  Verification: `rg -n "src-[0-9]{4}|\.\./" knowledge_base/bridges/midnight-cardano-recursive-bridge.md`

- [x] 3.2 **S01-T03-W02** Replace the top-level structure with the exact approved headings: Document control; Purpose and scope; System model; Terminology and invariants; Security and trust model; Bootstrap and roots of trust; Shared claim protocol; Predicate registry; Cardano predicate catalog; Midnight predicate catalog; Cardano state anchoring; Cardano to Midnight proof path; Midnight state anchoring; Midnight to Cardano proof path; Proof systems and setup; Reference harness; Trustless transaction protocol; Destination validators; Relaying and data availability; Governance and upgrades; Economics and performance; Conformance and security testing; Testnet deployment; Production path and residual risks; Appendices.
  Verification: `$heads = rg "^## [0-9]+\." knowledge_base/bridges/midnight-cardano-recursive-bridge.md; if ($heads.Count -ne 25) { throw "Expected 25 sections, got $($heads.Count)" }`

- [x] 3.3 **S01-T03-W03** Fill sections 1 through 8 by reconciling the existing thesis, component, trust, cost, and claim-interface material with the fixed proof-of-concept decisions, checkpoint and genesis modes, source-protocol fingerprints, canonical claim digest, proof-composition equalities, and nested artifact-binding graph.
  Verification: `$heads = rg "^## ([1-8])\." knowledge_base/bridges/midnight-cardano-recursive-bridge.md; if ($heads.Count -ne 8) { throw "Sections 1 through 8 are incomplete" }`

- [x] 3.4 **S01-T03-W04** Fill sections 9 through 15 with the 42/52 catalog contract without invented rows, the catalog-recovery gate, Cardano Mithril/SCLS anchoring, Midnight BEEFY/MMR anchoring, both fixed proof paths, recursion, BSB22 `claim_digest` binding, independent setup inventories, and current measured costs.
  Verification: `$heads = rg "^## (9|1[0-5])\." knowledge_base/bridges/midnight-cardano-recursive-bridge.md; if ($heads.Count -ne 7) { throw "Sections 9 through 15 are incomplete" }`

- [x] 3.5 **S01-T03-W05** Fill sections 16 through 25 with reference-harness interfaces, settlement transitions, relayer trust, governance, economics, conformance, deployment manifests, outcome labels, production gaps, the binary-format appendix, requirement traceability, and provenance; preserve every unresolved upstream dependency as a named gate.
  Verification: `$heads = rg "^## (1[6-9]|2[0-5])\." knowledge_base/bridges/midnight-cardano-recursive-bridge.md; if ($heads.Count -ne 10) { throw "Sections 16 through 25 are incomplete" }`

- [x] 3.6 **S01-T03-W06** Check the complete living-design shape and approved heading order.
  Verification: `$heads = rg "^## [0-9]+\." knowledge_base/bridges/midnight-cardano-recursive-bridge.md; if ($heads.Count -ne 25) { throw "Expected 25 sections, got $($heads.Count)" }`

- [x] 3.7 **S01-T03-W07** Commit only the populated living design as `Expand proof bridge living design`.
  Command: `git add knowledge_base/bridges/midnight-cardano-recursive-bridge.md; git commit -m "Expand proof bridge living design"`
  Verification: `git show --name-only --format=%s -1 | rg "Expand proof bridge living design|knowledge_base/bridges/midnight-cardano-recursive-bridge.md"`

## 4. Add documentation navigation and predicate-status coverage

**Files:** Modify `README.md`, `knowledge_base/index.md`, `EXAMINATION-CHECKLIST.md`, and `RESEARCH-PLAN.md`; create `knowledge_base/proof-claims/predicate-catalog-status.md`.

**Interface:** Consume the populated living design and Sprint 1 OpenSpec requirements. Produce discoverable documentation, explicit catalog status, and aligned trackers.

- [x] 4.1 **S01-T04-W01** Write predicate catalog status with the required counts, missing filenames and searched paths, required row fields, mechanical count/uniqueness/provenance gates, prohibition on invented filler rows, and distinction between predicate families and live-testnet subsets.
  Verification: `rg -n "42|52|missing|provenance|invent|live-testnet" knowledge_base/proof-claims/predicate-catalog-status.md`

- [x] 4.2 **S01-T04-W02** Link `README.md` and `knowledge_base/index.md` directly to the 25-section living design, program design, predicate catalog status, and `openspec/specs/` workflow.
  Verification: `rg -n "midnight-cardano-recursive-bridge|predicate-catalog-status|openspec" README.md knowledge_base/index.md`

- [x] 4.3 **S01-T04-W03** Align `EXAMINATION-CHECKLIST.md` and `RESEARCH-PLAN.md` with the 11-sprint, 62-package program, six activation gates, 25-section living design, hard 94-record catalog gate, and council plus Deep Research Toolkit workflow.
  Verification: `rg -n "11|62|four|25|94|council|Deep Research Toolkit" EXAMINATION-CHECKLIST.md RESEARCH-PLAN.md`

- [x] 4.4 **S01-T04-W04** Verify that living-design, predicate-status, and OpenSpec links are exposed from repository entry points and aligned trackers.
  Verification: `rg -n "midnight-cardano-recursive-bridge|predicate-catalog-status|openspec" README.md knowledge_base/index.md EXAMINATION-CHECKLIST.md RESEARCH-PLAN.md`

- [x] 4.5 **S01-T04-W05** Commit only the documentation navigation, status, and tracker files as `Align proof bridge documentation`.
  Command: `git add README.md knowledge_base/index.md EXAMINATION-CHECKLIST.md RESEARCH-PLAN.md knowledge_base/proof-claims/predicate-catalog-status.md; git commit -m "Align proof bridge documentation"`
  Verification: `git show --name-only --format=%s -1 | rg "Align proof bridge documentation|README.md|knowledge_base/index.md|EXAMINATION-CHECKLIST.md|RESEARCH-PLAN.md|predicate-catalog-status.md"`

## 5. Run Deep Research Toolkit and reader review

**Files:** Modify `knowledge_base/bridges/midnight-cardano-recursive-bridge.md` and `openspec/changes/sprint-01-foundation/review.md`.

**Interface:** Consume the compiled knowledge index and current design. Produce a verbatim-gated evidence dossier, council questions, dispositions, and a clean current-state rewrite.

- [x] 5.1 **S01-T05-W01** Compile the current knowledge base with the repository-local DuckDB home and fake embedder; require nonzero page, claim, entity, and relation counts.
  Verification: `New-Item -ItemType Directory -Force .deepresearch/duckdb-home | Out-Null; $localHome=(Resolve-Path .deepresearch/duckdb-home).Path; $env:HOME=$localHome; $env:USERPROFILE=$localHome; $env:DRT_FAKE_EMBEDDER='1'; .\.venv-drt\Scripts\python.exe _external\deep-research-toolkit\skills\knowledge-compiler\scripts\compile.py`

- [x] 5.2 **S01-T05-W02** Compose the roots-of-trust, proof-composition, predicate-registry, and testnet-deployment dossier sequentially, then adjudicate contradiction candidates; use only included claims with verbatim evidence.
  Verification: `$env:PYTHONIOENCODING='utf-8'; & .\.venv-drt\Scripts\python.exe _external\deep-research-toolkit\skills\retrieval-planner\scripts\query.py compose-dossier "roots of trust, proof composition, predicate registry, and testnet deployment for the Cardano Midnight bridge" --k 40; if ($LASTEXITCODE -ne 0) { throw "Dossier composition failed" }; & .\.venv-drt\Scripts\python.exe _external\deep-research-toolkit\skills\retrieval-planner\scripts\query.py find-contradictions; if ($LASTEXITCODE -ne 0) { throw "Contradiction search failed" }`

- [x] 5.3 **S01-T05-W03** Dispatch read-only proof-systems, consensus, and implementer/operator readers; record each reader's output SHA-256 and each blocking, major, and minor question with its location and acceptance evidence.
  Verification: `$review = Get-Content -Raw openspec/changes/sprint-01-foundation/review.md; foreach ($reader in @('Proof-systems', 'Consensus', 'Implementer/operator')) { $pattern = "(?m)^- \*\*$([regex]::Escape($reader)) reader:\*\* Complete; output SHA-256: [0-9a-f]{64}$"; if ($review -notmatch $pattern) { throw "$reader reader completion evidence is missing" } }`

- [x] 5.4 **S01-T05-W04** Resolve council questions in the current design and OpenSpec specs without revision narration, record dispositions in `review.md`, and run the Humanizer pass while preserving normative and cryptographic content.
  Verification: `$env:OPENSPEC_TELEMETRY='0'; npx openspec validate sprint-01-foundation --strict --no-interactive`

- [x] 5.5 **S01-T05-W05** Run a fresh current-document-only reread and close with zero blocking questions and zero unresolved major questions.
  Verification: `$review = Get-Content -Raw openspec/changes/sprint-01-foundation/review.md; foreach ($result in @('**Council gate:** closed', '**Blocking review questions:** 0', '**Unresolved major review questions:** 0')) { if (-not $review.Contains($result)) { throw "Missing council closure result: $result" } }`

- [ ] 5.6 **S01-T05-W06** Commit only the reconciled living design and review artifact as `Resolve proof bridge foundation review`.
  Command: `git add knowledge_base/bridges/midnight-cardano-recursive-bridge.md openspec/changes/sprint-01-foundation/review.md; git commit -m "Resolve proof bridge foundation review"`
  Verification: `git show --name-only --format=%s -1 | rg "Resolve proof bridge foundation review|knowledge_base/bridges/midnight-cardano-recursive-bridge.md|openspec/changes/sprint-01-foundation/review.md"`

## 6. Validate, archive, and verify the foundation

**Files:** Modify stable `openspec/specs/*/spec.md` through archive and move `openspec/changes/sprint-01-foundation/` through the OpenSpec archive operation.

**Interface:** Consume all completed foundation artifacts. Produce stable OpenSpec specs, an archived Sprint 1 change, and fresh verification evidence.

- [ ] 6.1 **S01-T06-W01** Run strict OpenSpec validation for all specs and the active change, plus verbose validation of the custom schema.
  Verification: `$env:OPENSPEC_TELEMETRY='0'; npm run openspec:validate; if ($LASTEXITCODE -ne 0) { throw "OpenSpec repository validation failed" }; npx openspec schema validate proof-bridge --verbose; if ($LASTEXITCODE -ne 0) { throw "proof-bridge schema validation failed" }`

- [ ] 6.2 **S01-T06-W02** Run whitespace, placeholder, and gated source-pack checks against the completed foundation.
  Verification: `git diff --check; if ($LASTEXITCODE -ne 0) { throw "Unstaged whitespace check failed" }; git diff --cached --check; if ($LASTEXITCODE -ne 0) { throw "Staged whitespace check failed" }; $placeholders = rg -n "TODO|TBD|FIXME|\[ \]" knowledge_base/bridges/midnight-cardano-recursive-bridge.md openspec --glob '!**/tasks.md'; if ($LASTEXITCODE -eq 0) { $placeholders; throw "Placeholder content remains" }; if ($LASTEXITCODE -ne 1) { throw "Placeholder scan failed" }; & .\.venv-drt\Scripts\python.exe _external\deep-research-toolkit\skills\research-knowledge-graph\scripts\check_claims.py research-runs/midnight-cardano-bridge-source-sweep-20260709; if ($LASTEXITCODE -ne 0) { throw "Bridge source pack failed" }; & .\.venv-drt\Scripts\python.exe _external\deep-research-toolkit\skills\research-knowledge-graph\scripts\check_claims.py research-runs/midnight-validator-set-sizing-20260709; if ($LASTEXITCODE -ne 0) { throw "Validator-set source pack failed" }`

- [ ] 6.3 **S01-T06-W03** Archive the accepted `sprint-01-foundation` change so its delta requirements become stable specs.
  Command: `$env:OPENSPEC_TELEMETRY='0'; npx openspec archive sprint-01-foundation --yes`
  Verification: `$archive = Get-ChildItem openspec/changes/archive -Directory -Filter '*sprint-01-foundation'; if ($archive.Count -ne 1) { throw "Expected one archived Sprint 1 change" }`

- [ ] 6.4 **S01-T06-W04** Revalidate the archived state and inspect the worktree for only intended foundation changes.
  Verification: `npm run openspec:validate; if ($LASTEXITCODE -ne 0) { throw "Archived OpenSpec validation failed" }; git status --short --branch; if ($LASTEXITCODE -ne 0) { throw "Worktree inspection failed" }`

- [ ] 6.5 **S01-T06-W05** Commit the validated, archived foundation as `Complete proof bridge documentation foundation`.
  Command: `git add .; git commit -m "Complete proof bridge documentation foundation"`
  Verification: `git show --stat --oneline -1 | rg "Complete proof bridge documentation foundation"`
