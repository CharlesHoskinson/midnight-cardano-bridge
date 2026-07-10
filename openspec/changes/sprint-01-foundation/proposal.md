## Why

The repository needs a normative foundation that turns the council-reviewed Cardano-Midnight bridge program into independently testable capability contracts. Establishing that baseline now prevents later proof, registry, settlement, and deployment work from hiding unresolved trust assumptions or substituting unapproved proof paths.

## What Changes

- Add baseline requirements for the bridge system, bootstrap trust, claim protocol, predicate registry, both source anchors, both fixed proof paths, the reference harness, settlement, operations and governance, and conformance testnet reporting.
- Bind the proof-of-concept to Cardano-to-Midnight Halo2/Plonk and Midnight-to-Cardano full-decider BSB22 commitment-Groth16 over BLS12-381.
- Establish deployment-domain, source-protocol-fingerprint, registry, artifact, replay, and outcome-label boundaries that later sprints must preserve.
- Treat four dependencies as hard feasibility gates: the **missing sibling catalogs**, which require recovery or source-backed reconstruction without invented rows; the **public Mithril SCLS profile**, which requires confirmation that the accepted public signer population certifies the exact signed-entity type; the authenticated **Midnight event-to-MMR path**, including its event-to-header binding; and the **full Halo2/KZG decider wrapper**, which must reject an invalid accumulator and report a measured resource profile.
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
