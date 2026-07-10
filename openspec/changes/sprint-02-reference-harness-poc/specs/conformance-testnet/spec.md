## ADDED Requirements

### Requirement: Scrapling source observations remain untrusted
Read-only public endpoint access in this change SHALL use Scrapling. Each
normalized observation SHALL bind schema version, chain, network, endpoint,
request method and body digest, observation time, raw response digest, adapter
revision, and `trust = unsigned-observation`. Captured fixtures SHALL retain the
same provenance fields. An endpoint response SHALL NOT count as finality,
checkpoint approval, proof verification, destination execution, or gate closure.

#### Scenario: Midnight and Mithril endpoints respond
- **WHEN** the adapters successfully read a Midnight finalized-head response and a Mithril certificate listing
- **THEN** they SHALL emit unsigned observations and leave every affected gate unresolved

#### Scenario: A captured response is relabeled authenticated
- **WHEN** a fixture or caller changes `trust` from `unsigned-observation`
- **THEN** fixture validation SHALL reject it

### Requirement: Structural result is not an outcome label
The conformance command SHALL report `structural-pass` or `structural-fail` for the
implemented codecs, parsers, and fixtures. It SHALL NOT emit `live-pass` or
`degraded-lab`. `OutcomeClassifierV1` SHALL remain `blocked` while any required
gate or either confirmed destination transition is absent.

#### Scenario: Every structural test passes while execution gates are open
- **WHEN** both language harnesses and every parser and observation-fixture test pass but `S01-BLOCK-05` or `S01-BLOCK-06` is unresolved
- **THEN** the command SHALL report `structural-pass` and deployment outcome `blocked`
