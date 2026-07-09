# Resolve Checklist Full Sweep Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Resolve every checklist item that can be answered from public primary sources or local repository evidence, and mark unavailable upstream-dependent items as blocked with evidence.

**Architecture:** This is a documentation and research sweep, not an application implementation. Evidence is gathered from primary sources, then distilled into `EXAMINATION-CHECKLIST.md`, the bridge design document, `RESEARCH-PLAN.md`, and any focused knowledge-base pages needed to keep claims traceable.

**Tech Stack:** Markdown, Git, ripgrep, GitHub primary sources, local cloned upstream repositories when needed.

## Global Constraints

- Do not invent answers for unpublished upstream specifications; mark them blocked or unresolved with the exact missing source.
- Prefer primary sources: official repos, CIPs, specifications, papers, and project documentation.
- Keep `EXAMINATION-CHECKLIST.md` as the operative tracker and make status changes explicit.
- Update the main design document only where resolved evidence changes architecture, constraints, or open problems.
- Do not add generated databases or fetched raw corpora unless the repository already tracks them.

---

### Task 1: Direction A Verifier And Relay Evidence

**Files:**
- Modify: `EXAMINATION-CHECKLIST.md`
- Modify: `knowledge_base/bridges/midnight-cardano-recursive-bridge.md`
- Modify: `knowledge_base/sources/index.md` if new primary sources are cited

**Interfaces:**
- Consumes: current Direction A checklist section.
- Produces: resolved or blocked statuses for relay encoding, Cardano-side verifier location, MMR/event inclusion, and relayer liveness.

- [x] Read primary source material for `midnight-node/relay`, partner-chain bridge smart contracts, and Cardano-side bridge validator artifacts.
- [x] Record whether the Cardano-side BEEFY verifier is public, and if found, cite the exact path and verification responsibilities.
- [x] Resolve what the signed MMR root commits to, or mark the remaining gap with the exact missing artifact.
- [x] Update Direction A checklist statuses and the main design open-problem text.

### Task 2: Direction B Finality, SCLS, And Current CMST Replacement

**Files:**
- Modify: `EXAMINATION-CHECKLIST.md`
- Modify: `knowledge_base/bridges/midnight-cardano-recursive-bridge.md`
- Modify: `knowledge_base/sources/index.md` if new primary sources are cited

**Interfaces:**
- Consumes: current Direction B checklist section.
- Produces: evidence-backed status for Mithril encoding, SCLS constraints, CMST trustless statement, and c2m bridge replacement target.

- [x] Read Mithril primary sources for curve, certificate structure, signer registration, and verification flow.
- [x] Read c2m bridge and partner-chain bridge primary sources where publicly available.
- [x] Write a precise trustless CMST circuit statement based on available evidence.
- [x] Update Direction B checklist statuses and design-document recommendations.

### Task 3: Midnight Consensus, Proving, Ledger, And Asset Details

**Files:**
- Modify: `EXAMINATION-CHECKLIST.md`
- Modify: `knowledge_base/bridges/midnight-cardano-recursive-bridge.md` if architecture changes
- Add or modify focused `knowledge_base/midnight/*.md` pages only when a resolved item needs traceable prose
- Modify: `knowledge_base/sources/index.md` if new primary sources are cited

**Interfaces:**
- Consumes: checklist sections C, D, E, and L.
- Produces: resolved statuses for validator selection, GRANDPA encoding, recursion, SRS posture, ZKIR details, Zswap/NIGHT/DUST, state roots, and transaction validity where public sources exist.

- [x] Read current Midnight docs and repos for consensus, proof aggregation, ledger specs, and asset specs.
- [x] Resolve public facts and mark future-release-only items as blocked with evidence.
- [x] Update checklist sections C, D, E, and L with exact source paths.

### Task 4: Cardano Verifier Budget, Cryptography, Security, And Operations

**Files:**
- Modify: `EXAMINATION-CHECKLIST.md`
- Modify: `knowledge_base/bridges/midnight-cardano-recursive-bridge.md` if design tradeoffs change
- Modify: `knowledge_base/sources/index.md` if new primary sources are cited

**Interfaces:**
- Consumes: checklist sections F, G, H, I, and J.
- Produces: resolved or blocked statuses for Cardano builtins/cost basis, mode decision matrix, trusted setup, threat model, replay, data availability, fees, batching, and governance.

- [x] Read Cardano ledger/Plutus/CIP primary sources for signature builtins and current cost-model evidence.
- [x] Read apk-proofs and bridge/security precedent sources needed for trust assumptions.
- [x] Update checklist sections F, G, H, I, and J with resolved facts and remaining measurement-only gaps.

### Task 5: Proof-Claim Envelope And Cross-Cutting Decisions

**Files:**
- Modify: `EXAMINATION-CHECKLIST.md`
- Modify: `knowledge_base/bridges/midnight-cardano-recursive-bridge.md`
- Add or modify `knowledge_base/proof-claims/*.md` only when needed for traceability

**Interfaces:**
- Consumes: checklist sections M and N.
- Produces: locked decisions where evidence is sufficient and explicit unresolved decisions where implementation or upstream source gaps remain.

- [x] Reconcile the relay proof shape with the proof-claim envelope fields.
- [x] Lock the cross-cutting decisions that follow from resolved evidence.
- [x] Update sections M and N and propagate any design impact.

### Task 6: Verification

**Files:**
- Read: all modified Markdown files.

**Interfaces:**
- Consumes: all changes from Tasks 1-5.
- Produces: final verification result and a concise residual-risk summary.

- [x] Run `git diff --check`.
- [x] Run `rg -n "TODO|TBD|FIXME|\\[ \\]" EXAMINATION-CHECKLIST.md knowledge_base/bridges/midnight-cardano-recursive-bridge.md`.
- [x] Run `rg -n "src-[0-9]{4}" knowledge_base/sources/index.md`.
- [x] Run `git status --short --branch`.
