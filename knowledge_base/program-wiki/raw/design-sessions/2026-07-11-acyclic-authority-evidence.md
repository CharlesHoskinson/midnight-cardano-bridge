---
id: source.design-session.2026-07-11-acyclic-authority-evidence
type: design-session
recorded_at: 2026-07-11T05:16:21Z
status: immutable-on-commit
---

# Acyclic authority and evidence session

This record backs the 2026-07-11 review entry in the program wiki log.

The session separated immutable credential handles from review, pre-fetch, and
pre-sign probe receipts. It required an operator-carried hash to authenticate the
whole build qualification before an elevated installer trusts embedded pins.

The closure envelope has one fixed path outside its own typed inventory. The
controller validates the complete delta, commits and integrates equal trees, and
publishes only the returned integration commit.

Historical KZG qualification remains distinct from new or updated ceremonies.
Registry activation precedes artifact authorization. Concrete ABI instances are
deployment observations, destination state does not contain a receipt digest
that would make its own authentication circular, and the terminal classifier
binds the final evidence-head record.
