## Why

The repository needs a normative foundation that turns the council-reviewed Cardano-Midnight bridge program into independently testable capability contracts. Establishing that baseline now prevents later proof, registry, settlement, and deployment work from hiding unresolved trust assumptions or substituting unapproved proof paths.

## What Changes

- Add baseline requirements for the bridge system, bootstrap trust, claim protocol, predicate registry, both source anchors, both fixed proof paths, the reference harness, settlement, operations and governance, and conformance testnet reporting.
- Bind the proof-of-concept to Cardano-to-Midnight Halo2/Plonk and Midnight-to-Cardano full-decider BSB22 commitment-Groth16 over BLS12-381.
- Establish deployment-domain, source-protocol-fingerprint, registry, artifact, replay, and outcome-label boundaries that later sprints must preserve.
- Treat six dependencies as hard activation gates: the **missing sibling catalogs**, the **public Mithril SCLS profile**, the authenticated **Midnight event-to-MMR path**, the **full Halo2/KZG decider wrapper**, the deployed **Midnight external-proof operation**, and the reference **Cardano BSB22/Plutus boundary**. Each has exact evidence in the published gate roster; none may be replaced by an inferred row, mocked relation, or library-only capability.
- Define the implementation and review sequence for completing the canonical 25-section design, documentation coverage, evidence-gated council review, and foundation validation and archive.

## Capabilities

### New Capabilities

- `bridge-system`: Bidirectional typed foreign-chain claims and destination authorization boundaries.
- `bootstrap-trust`: Deployment-bound checkpoint and genesis trust profiles.
- `claim-protocol`: Canonical, proof-bound claim statements and validation behavior.
- `predicate-registry`: Authorized predicate, proof-suite, architecture, key, and SRS semantics.
- `cardano-anchor`: Named Mithril and SCLS trust profiles for Cardano facts.
- `midnight-anchor`: Authenticated BEEFY, header, MMR, and event paths for Midnight facts.
- `halo2-proof-path`: Cardano-to-Midnight Halo2/Plonk verification and atomic state transition.
- `groth16-proof-path`: Midnight-to-Cardano full-decider BSB22 commitment-Groth16 landing.
- `reference-harness`: Symmetric offline and live query, proof, verification, and submission flows.
- `settlement-protocol`: Concurrent, replay-safe claim consumption under tracked anchors.
- `operations-governance`: Immutable proof-of-concept roots, freeze behavior, and deployment-domain changes.
- `conformance-testnet`: Testable conformance evidence and honest live-pass, degraded-lab, or blocked reporting.

### Modified Capabilities

None.

## Impact

This change creates the normative inputs for the living bridge design, predicate catalog and registry, proof circuits, destination validators, reference harness, settlement clients, deployment manifests, conformance vectors, traceability records, and independent proof, consensus, and operator review. It adds specifications only; implementation remains gated by the named Sprint 1 and Sprint 2 dependencies.
