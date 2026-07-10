# Proof bridge foundation and living design implementation plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Install a validated OpenSpec foundation and replace the current bridge synthesis with the approved, fully populated 25-section living design.

**Architecture:** OpenSpec 1.5.0 is pinned locally and extended with a council-review artifact. One Sprint 1 change introduces twelve stable capability specs, while the existing bridge page remains the canonical human-readable design. The document uses the repository knowledge base and gated source packs; missing predicate catalogs remain an explicit blocking input and are never reconstructed by count alone.

**Tech Stack:** Markdown, OpenSpec 1.5.0, npm package lock, YAML, CDDL/JSON-oriented protocol descriptions, Deep Research Toolkit, Git, PowerShell, ripgrep.

## Global constraints

- Pin `@fission-ai/openspec` to exactly `1.5.0`.
- Use the custom artifact order `proposal -> specs -> design -> tasks -> review`.
- Run OpenSpec with `OPENSPEC_TELEMETRY=0`.
- Keep `knowledge_base/bridges/midnight-cardano-recursive-bridge.md` as the canonical narrative.
- Populate all 25 approved sections with current facts, decisions, requirements, or explicit evidence gaps.
- Do not invent the missing 42- and 52-predicate catalog entries.
- Keep the PoC proof paths fixed: Cardano facts use Halo2/Plonk on Midnight; Midnight facts use a full BSB22 commitment-Groth16 landing on Cardano.
- Label outcomes `live-pass`, `degraded-lab`, or `blocked`; only `live-pass` satisfies the public-testnet PoC goal.
- Treat PoC trust roots as immutable within one deployment domain.
- Use primary sources or verbatim-gated local source packs for load-bearing chain claims.
- Run the Humanizer editing pass without changing normative requirements, identifiers, formulas, thresholds, or source language.
- Keep revision history in Git and review artifacts, not in the canonical design body.

---

### Task 1: Pin and initialize OpenSpec

**Files:**
- Create: `package.json`
- Create: `package-lock.json`
- Create: `openspec/config.yaml`
- Create: `openspec/schemas/proof-bridge/schema.yaml`
- Create: `openspec/schemas/proof-bridge/templates/review.md`
- Modify or create through OpenSpec: `AGENTS.md`

**Interfaces:**
- Consumes: program rules from `docs/superpowers/specs/2026-07-09-midnight-cardano-proof-bridge-program-design.md`.
- Produces: local `npm run openspec:validate`, schema `proof-bridge`, and project context injected into every change artifact.

- [ ] **Step 1: Create the pinned package manifest**

```json
{
  "name": "midnight-cardano-proof-bridge",
  "private": true,
  "scripts": {
    "openspec:validate": "openspec validate --all --strict --no-interactive"
  },
  "devDependencies": {
    "@fission-ai/openspec": "1.5.0"
  }
}
```

- [ ] **Step 2: Generate the package lock**

Run:

```powershell
$env:OPENSPEC_TELEMETRY='0'
npm install --package-lock-only
```

Expected: `package-lock.json` pins `@fission-ai/openspec` version `1.5.0`.

- [ ] **Step 3: Initialize Codex support**

Run:

```powershell
$env:OPENSPEC_TELEMETRY='0'
npx openspec init . --tools codex --force
```

Expected: an `openspec/` root and Codex-facing repository instructions exist.

- [ ] **Step 4: Fork the standard schema**

Run:

```powershell
$env:OPENSPEC_TELEMETRY='0'
npx openspec schema fork spec-driven proof-bridge
```

Expected: `openspec/schemas/proof-bridge/` contains `schema.yaml` and four standard templates.

- [ ] **Step 5: Add the review artifact**

Append this artifact after `tasks` in `schema.yaml`:

```yaml
  - id: review
    generates: review.md
    description: Independent proof, consensus, and operator review
    template: review.md
    instruction: |
      Record reader questions and their dispositions.
      Group questions as BLOCKING, MAJOR, or MINOR.
      Each entry names its document location, technical reason, required evidence,
      disposition, and verification result.
      Do not copy revision narration into the canonical bridge design.
    requires:
      - specs
      - design
      - tasks
```

Create `templates/review.md`:

```markdown
## Evidence dossier

## Blocking questions

## Major questions

## Minor questions

## Dispositions

## Verification
```

Change the schema name and description:

```yaml
name: proof-bridge
version: 1
description: Proof bridge workflow with independent council review
```

- [ ] **Step 6: Configure project context**

Set `openspec/config.yaml` to:

```yaml
schema: proof-bridge
context: |
  Project: Bidirectional Cardano and Midnight proof bridge.
  Canonical design: knowledge_base/bridges/midnight-cardano-recursive-bridge.md.
  Proof paths: Cardano to Midnight uses Halo2/Plonk; Midnight to Cardano uses
  full-decider BSB22 commitment-Groth16 over BLS12-381.
  Source policy: primary sources and verbatim-gated Deep Research Toolkit packs.
  PoC roots are immutable within a deployment domain.
  Missing predicate catalog rows may not be invented.
rules:
  proposal:
    - Name affected capability specs and hard feasibility gates.
  specs:
    - Use MUST or SHALL and at least one WHEN/THEN scenario per requirement.
    - State trust assumptions and negative behavior for security requirements.
  design:
    - Bind every proof statement to a source protocol fingerprint and deployment domain.
    - Include failure outcomes and rollback or freeze behavior.
  tasks:
    - Give each task a stable work-package id and verification command.
  review:
    - Use independent proof, consensus, and operator readers.
    - Resolve every blocking and major question before archive.
```

- [ ] **Step 7: Validate the schema and empty project**

Run:

```powershell
$env:OPENSPEC_TELEMETRY='0'
npx openspec schema validate proof-bridge --verbose
npm run openspec:validate
```

Expected: schema validation succeeds; project validation reports no invalid specs or changes.

- [ ] **Step 8: Commit**

```powershell
git add package.json package-lock.json AGENTS.md openspec
git commit -m "Initialize proof bridge OpenSpec workflow"
```

### Task 2: Create the Sprint 1 OpenSpec change

**Files:**
- Create: `openspec/changes/sprint-01-foundation/proposal.md`
- Create: `openspec/changes/sprint-01-foundation/design.md`
- Create: `openspec/changes/sprint-01-foundation/tasks.md`
- Create: `openspec/changes/sprint-01-foundation/review.md`
- Create: `openspec/changes/sprint-01-foundation/specs/*/spec.md`

**Interfaces:**
- Consumes: schema `proof-bridge` and the council-reviewed program design.
- Produces: delta requirements for all twelve stable capability domains.

- [ ] **Step 1: Scaffold the change**

Run:

```powershell
$env:OPENSPEC_TELEMETRY='0'
npx openspec new change sprint-01-foundation --schema proof-bridge --description "Establish OpenSpec and the 25-section bridge design"
```

Expected: `openspec/changes/sprint-01-foundation/` exists.

- [ ] **Step 2: Write the proposal**

The proposal SHALL name these new capabilities:

```text
bridge-system
bootstrap-trust
claim-protocol
predicate-registry
cardano-anchor
midnight-anchor
halo2-proof-path
groth16-proof-path
reference-harness
settlement-protocol
operations-governance
conformance-testnet
```

It SHALL identify the missing sibling catalogs, public Mithril SCLS profile,
Midnight event-to-MMR path, and full Halo2/KZG decider wrapper as hard gates.

- [ ] **Step 3: Write one baseline requirement per capability**

Create the following exact requirement names and scenario purposes:

| Capability | Requirement | Scenario |
| --- | --- | --- |
| bridge-system | Bidirectional typed claims | Each direction verifies a foreign claim before local authorization |
| bootstrap-trust | Deployment-bound checkpoint | A proof from another checkpoint or deployment domain is rejected |
| claim-protocol | Canonical claim digest | Mutating any proof-bound field changes verification |
| predicate-registry | Authorized proof semantics | An unregistered VK, suite, architecture, or SRS is rejected |
| cardano-anchor | Named Cardano trust profile | A project-operated signer proof cannot claim public-testnet trust |
| midnight-anchor | Authenticated Midnight event path | A fact without an event-to-MMR path is rejected |
| halo2-proof-path | Cardano proof on Midnight | The Midnight operation checks the full Cardano statement and updates state atomically |
| groth16-proof-path | Full-decider BSB22 landing | An invalid KZG accumulator is rejected by the wrapped relation |
| reference-harness | Symmetric query and proof flow | Offline and live adapters produce the same canonical statement |
| settlement-protocol | Concurrent claim consumption | Distinct claims may consume one current anchor without duplicate settlement |
| operations-governance | Immutable PoC roots | Replacing a PoC root requires a new deployment domain |
| conformance-testnet | Honest outcome labels | Lab or blocked paths cannot be reported as live-pass |

Every requirement SHALL include at least one `#### Scenario` with `WHEN` and `THEN` bullets.

- [ ] **Step 4: Write the change design and task checklist**

The change design SHALL point to the 25-section outline and explain why the
canonical narrative and normative OpenSpec specs remain separate. The task file
SHALL contain Task 3 through Task 6 from this implementation plan as checkboxes.

- [ ] **Step 5: Validate the active change**

Run:

```powershell
$env:OPENSPEC_TELEMETRY='0'
npx openspec validate sprint-01-foundation --strict --no-interactive
```

Expected: all twelve delta specs and all five artifacts validate.

- [ ] **Step 6: Commit**

```powershell
git add openspec/changes/sprint-01-foundation
git commit -m "Specify proof bridge foundation"
```

### Task 3: Populate the canonical 25-section bridge design

**Files:**
- Modify: `knowledge_base/bridges/midnight-cardano-recursive-bridge.md`

**Interfaces:**
- Consumes: all current knowledge-base pages, the program design, and gated source packs.
- Produces: one current-state narrative with exactly 25 numbered top-level sections.

- [ ] **Step 1: Preserve provenance and source links**

Run:

```powershell
rg -n "src-[0-9]{4}|\\.\\./" knowledge_base/bridges/midnight-cardano-recursive-bridge.md
```

Expected: existing source references and relative links are available for reuse.

- [ ] **Step 2: Replace the top-level structure**

Use these exact top-level headings:

```markdown
## 1. Document control
## 2. Purpose and scope
## 3. System model
## 4. Terminology and invariants
## 5. Security and trust model
## 6. Bootstrap and roots of trust
## 7. Shared claim protocol
## 8. Predicate registry
## 9. Cardano predicate catalog
## 10. Midnight predicate catalog
## 11. Cardano state anchoring
## 12. Cardano to Midnight proof path
## 13. Midnight state anchoring
## 14. Midnight to Cardano proof path
## 15. Proof systems and setup
## 16. Reference harness
## 17. Trustless transaction protocol
## 18. Destination validators
## 19. Relaying and data availability
## 20. Governance and upgrades
## 21. Economics and performance
## 22. Conformance and security testing
## 23. Testnet deployment
## 24. Production path and residual risks
## 25. Appendices
```

- [ ] **Step 3: Fill sections 1 through 8**

Move and reconcile existing thesis, component, trust, cost, and claim-interface
material. Add the current PoC decisions, checkpoint/genesis modes,
source-protocol fingerprints, claim digest, proof composition equality, and
nested artifact-binding graph.

- [ ] **Step 4: Fill sections 9 through 15**

Describe the 42/52 catalog contract without inventing missing rows. Preserve the
catalog-recovery gate. Move Cardano Mithril/SCLS material, Midnight BEEFY/MMR
material, both proof paths, recursion, BSB22 claim-digest binding, setup
inventories, and current measured costs into their named sections.

- [ ] **Step 5: Fill sections 16 through 25**

Specify the reference harness interfaces, settlement transitions, relayer trust,
governance, economics, conformance, deployment manifests, outcome labels,
production gaps, binary-format appendix, requirement traceability, and
provenance. Preserve every unresolved upstream dependency as a named gate.

- [ ] **Step 6: Check document shape**

Run:

```powershell
$heads = rg "^## [0-9]+\\." knowledge_base/bridges/midnight-cardano-recursive-bridge.md
if ($heads.Count -ne 25) { throw "Expected 25 sections, got $($heads.Count)" }
```

Expected: exactly 25 numbered top-level headings in the approved order.

- [ ] **Step 7: Commit**

```powershell
git add knowledge_base/bridges/midnight-cardano-recursive-bridge.md
git commit -m "Expand proof bridge living design"
```

### Task 4: Add documentation navigation and predicate-status coverage

**Files:**
- Modify: `README.md`
- Modify: `knowledge_base/index.md`
- Modify: `EXAMINATION-CHECKLIST.md`
- Modify: `RESEARCH-PLAN.md`
- Create: `knowledge_base/proof-claims/predicate-catalog-status.md`

**Interfaces:**
- Consumes: populated living design and Sprint 1 OpenSpec requirements.
- Produces: discoverable documentation, explicit catalog status, and aligned trackers.

- [ ] **Step 1: Write predicate catalog status**

The status page SHALL state the required counts, missing filenames and searched
paths, required row fields, mechanical count/uniqueness/provenance gates,
prohibition on invented filler rows, and relationship between predicate families
and live-testnet subsets.

- [ ] **Step 2: Link the living design and OpenSpec workflow**

Add direct links from `README.md` and `knowledge_base/index.md` to the 25-section
design, program design, predicate catalog status, and `openspec/specs/`.

- [ ] **Step 3: Align trackers**

Update `EXAMINATION-CHECKLIST.md` and `RESEARCH-PLAN.md` with the 11-sprint,
62-package program, four early feasibility gates, 25-section living design, hard
94-record catalog gate, and council plus Deep Research Toolkit workflow.

- [ ] **Step 4: Verify links**

```powershell
rg -n "midnight-cardano-recursive-bridge|predicate-catalog-status|openspec" README.md knowledge_base/index.md EXAMINATION-CHECKLIST.md RESEARCH-PLAN.md
```

Expected: each artifact is linked from at least one repository entry point.

- [ ] **Step 5: Commit**

```powershell
git add README.md knowledge_base/index.md EXAMINATION-CHECKLIST.md RESEARCH-PLAN.md knowledge_base/proof-claims/predicate-catalog-status.md
git commit -m "Align proof bridge documentation"
```

### Task 5: Run Deep Research Toolkit and reader review

**Files:**
- Modify: `knowledge_base/bridges/midnight-cardano-recursive-bridge.md`
- Modify: `openspec/changes/sprint-01-foundation/review.md`

**Interfaces:**
- Consumes: compiled knowledge index and current design.
- Produces: evidence dossier, council questions, dispositions, and a clean rewrite.

- [ ] **Step 1: Compile the current knowledge base**

```powershell
New-Item -ItemType Directory -Force .deepresearch/duckdb-home | Out-Null
$localHome=(Resolve-Path .deepresearch/duckdb-home).Path
$env:HOME=$localHome
$env:USERPROFILE=$localHome
$env:DRT_FAKE_EMBEDDER='1'
.\.venv-drt\Scripts\python.exe _external\deep-research-toolkit\skills\knowledge-compiler\scripts\compile.py
```

Expected: compilation succeeds and reports nonzero pages, claims, entities, and relations.

- [ ] **Step 2: Compose the evidence dossier sequentially**

```powershell
$env:PYTHONIOENCODING='utf-8'
.\.venv-drt\Scripts\python.exe _external\deep-research-toolkit\skills\retrieval-planner\scripts\query.py compose-dossier "roots of trust, proof composition, predicate registry, and testnet deployment for the Cardano Midnight bridge" --k 40
.\.venv-drt\Scripts\python.exe _external\deep-research-toolkit\skills\retrieval-planner\scripts\query.py find-contradictions
```

Expected: included claims have verbatim evidence; rejected claims are not used.

- [ ] **Step 3: Run the three-reader council**

Dispatch read-only proof, consensus, and operator readers. Each returns blocking,
major, and minor questions with locations and acceptance criteria.

- [ ] **Step 4: Resolve questions without revision narration**

Update the current design and OpenSpec specs directly. Record questions and
dispositions in `review.md`. Run the Humanizer pass on explanatory prose while
preserving normative and cryptographic content.

- [ ] **Step 5: Run a fresh reread**

Use current-document-only prompts. The gate is zero blocking questions and zero
unresolved major questions.

- [ ] **Step 6: Commit**

```powershell
git add knowledge_base/bridges/midnight-cardano-recursive-bridge.md openspec/changes/sprint-01-foundation/review.md
git commit -m "Resolve proof bridge foundation review"
```

### Task 6: Validate, archive, and verify the foundation

**Files:**
- Modify through archive: `openspec/specs/*/spec.md`
- Move through archive: `openspec/changes/sprint-01-foundation/`

**Interfaces:**
- Consumes: all completed foundation artifacts.
- Produces: stable OpenSpec specs, archived Sprint 1 change, and fresh verification evidence.

- [ ] **Step 1: Run strict OpenSpec validation**

```powershell
$env:OPENSPEC_TELEMETRY='0'
npm run openspec:validate
npx openspec schema validate proof-bridge --verbose
```

Expected: all specs and the active change pass strict validation.

- [ ] **Step 2: Run documentation and source checks**

```powershell
git diff --check
rg -n "TODO|TBD|FIXME|\\[ \\]" knowledge_base/bridges/midnight-cardano-recursive-bridge.md openspec
.\.venv-drt\Scripts\python.exe _external\deep-research-toolkit\skills\research-knowledge-graph\scripts\check_claims.py research-runs/midnight-cardano-bridge-source-sweep-20260709
.\.venv-drt\Scripts\python.exe _external\deep-research-toolkit\skills\research-knowledge-graph\scripts\check_claims.py research-runs/midnight-validator-set-sizing-20260709
```

Expected: no whitespace errors or placeholders; both claim packs pass.

- [ ] **Step 3: Archive the accepted change**

```powershell
$env:OPENSPEC_TELEMETRY='0'
npx openspec archive sprint-01-foundation --yes
```

Expected: delta requirements become stable specs and the change moves under the archive.

- [ ] **Step 4: Revalidate archived state**

```powershell
npm run openspec:validate
git status --short --branch
```

Expected: strict validation passes and only intended foundation files remain staged or modified.

- [ ] **Step 5: Commit**

```powershell
git add .
git commit -m "Complete proof bridge documentation foundation"
```
