# gnark commitment-aware MPC source receipt addendum

Source id: `source.external.gnark-bsb22-mpc.2026-07-12`
Record type: external raw-source receipt
Retrieved at: 2026-07-12T02:09:53Z
Supersedes: `source.external.gnark-bsb22-mpc.2026-07-10` for the observations below

## Acquisition

Scrapling 0.4.10 `Fetcher.get` retrieved the three raw URLs at gnark commit
`0dc3be8cad8af3943924fd36b190ebefc6094a4e`. Counts and SHA-256 values cover
`response.body` before decoding. Each value matches the pinned Git object record
in the earlier receipt.

| Path | Git blob | Bytes | SHA-256 |
| --- | --- | ---: | --- |
| `backend/groth16/bls12-381/mpcsetup/phase1.go` | `ffebefa2acd9582d09efa641838e2ff75587a4d1` | 8,973 | `20376f62c2419a404214f24accf8b49dfdc24c3e31ef6f9789e80e4c2448042d` |
| `backend/groth16/bls12-381/mpcsetup/phase2.go` | `f409ce09fc3ad2afc7f2a7ccfd1da79bb6503bd1` | 12,838 | `8607f5d6576120ce99c645a0e92d229f77d8564f2d9fea3b5a1f24510914c411` |
| `backend/groth16/bls12-381/mpcsetup/setup.go` | `4f49cb4e2dd16746f94371210b69a0a3d1020e39` | 3,831 | `e61eb9b26d9a641679936404187a484d7f3b6db3965abe646ca293fedf502038` |

Raw URL prefix:
`https://raw.githubusercontent.com/CharlesHoskinson/gnark/0dc3be8cad8af3943924fd36b190ebefc6094a4e/`

## Observations

- Phase 1 contributes and verifies `tau`, `alpha`, and `beta` updates.
- Commitment-aware Phase 2 verifies one proof of knowledge for each `sigma` update across the corresponding G1 commitment bases and G2 sigma point.
- The Phase 2 delta proof of knowledge covers G1 delta, G2 delta, and the inverse-scaled G1 `Z` and `PKK` terms. The `Z` and `PKK` update pairs are intentionally passed in reverse order because delta is in their denominator.
- Key sealing derives every `GSigmaNeg` from the negated G2 sigma point and uses the standard BLS12-381 G2 generator for `gamma`.
- Phase 1 and Phase 2 accept beacon inputs. This source does not define the bridge's future-beacon schedule or contributor-independence policy.

This receipt establishes source identity and the listed observations. It does not
approve the fork, ceremony framework, setup output, contributor set, or deployed
keys.
