## ADDED Requirements

### Requirement: Scrapling source observations remain untrusted
Read-only public endpoint access in this change SHALL use Scrapling. Each
normalized observation SHALL bind schema version, chain, network, endpoint,
request method and body digest, observation time, raw response digest, adapter
revision, and `trust = unsigned-observation`. Captured fixtures SHALL retain the
same provenance fields plus exact request and response body bytes and HTTP
statuses. Capture validation SHALL recompute both digests, parse those preserved
bytes, and reject a trust relabel, unknown field, duplicate or unknown gate id,
body tamper, provenance tamper, or any positive finality, SCLS, inclusion,
proof-verification, or execution claim. Observation validation SHALL rederive the
aggregate request and response digests, response statuses, and complete
chain-specific normalized data object from the validated capture and require
exact equality. An endpoint response SHALL NOT count as finality, checkpoint
approval, proof verification, destination execution, or gate closure.

#### Scenario: Midnight and Mithril endpoints respond
- **WHEN** the adapters successfully read a Midnight finalized-head response and a Mithril certificate listing
- **THEN** Midnight SHALL reference exactly `S01-BLOCK-03/event-inclusion`, Mithril SHALL reference exactly `S01-BLOCK-02/public-scls-availability`, and both SHALL leave those gates unresolved

#### Scenario: A captured response is relabeled authenticated
- **WHEN** a fixture or caller changes `trust` from `unsigned-observation`
- **THEN** fixture validation SHALL reject it

#### Scenario: Normalized endpoint data diverges from preserved bytes
- **WHEN** a caller changes any response-derived Midnight or Mithril data member without changing the validated capture
- **THEN** observation validation SHALL reject the record before evidence publication

#### Scenario: An endpoint invents an SCLS-looking type name
- **WHEN** a Mithril response includes an unregistered type name containing `SCLS` or a caller adds a positive SCLS field
- **THEN** normalization SHALL report the endpoint-supplied type name without interpreting it and closed-schema validation SHALL reject the positive claim

### Requirement: Structural result is not an outcome label
The conformance command SHALL report `structural-pass` or `structural-fail` for the
implemented codecs, parsers, and fixtures. It SHALL NOT emit `live-pass` or
`degraded-lab`. `OutcomeClassifierV1` SHALL remain `blocked` while any required
gate or either confirmed destination transition is absent.

#### Scenario: Every structural test passes while execution gates are open
- **WHEN** both language harnesses and every parser and observation-fixture test pass but `S01-BLOCK-05` or `S01-BLOCK-06` is unresolved
- **THEN** the command SHALL report `structural-pass` and deployment outcome `blocked`
