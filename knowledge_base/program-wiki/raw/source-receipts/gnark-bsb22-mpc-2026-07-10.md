# gnark commitment-aware MPC source receipt

Source id: `source.external.gnark-bsb22-mpc.2026-07-10`
Record type: external Git and raw-source receipt
Retrieved at: 2026-07-10T23:47:06Z

Authority: exact upstream Git objects from
`https://github.com/CharlesHoskinson/gnark`, as pinned by the reviewed
`proof-zk-recovery` ceremony source.

## Pin chain

- `proof-zk-recovery` ceremony commit:
  `6c5dc257a9804b6b88bad20541b5bac46fff8dbd`
- Pin file: `proto/ceremony/go.mod`
- Pin-file blob: `c82a4dc17dc47270dfa0d1e2ab4aec1568bb321f`
- Pin-file bytes: 839
- Pin-file SHA-256:
  `410a22fd5e6ff24022e45d0d3cbba9b8a866310059215e30a79a3f16c57e7692`
- Declared replacement: `github.com/CharlesHoskinson/gnark` at
  `0dc3be8cad8a`
- Resolved gnark commit:
  `0dc3be8cad8af3943924fd36b190ebefc6094a4e`
- Resolved gnark tree:
  `b13f906c69d5eec618aaaf601ba370de48583c6f`

## Retrieved source objects

Scrapling `Fetcher.get` retrieved each raw URL. The byte count and SHA-256 cover
the exact `response.body` bytes before text decoding.

| Path | Git blob | Bytes | SHA-256 |
| --- | --- | ---: | --- |
| `backend/groth16/bls12-381/mpcsetup/phase1.go` | `ffebefa2acd9582d09efa641838e2ff75587a4d1` | 8,973 | `20376f62c2419a404214f24accf8b49dfdc24c3e31ef6f9789e80e4c2448042d` |
| `backend/groth16/bls12-381/mpcsetup/phase2.go` | `f409ce09fc3ad2afc7f2a7ccfd1da79bb6503bd1` | 12,838 | `8607f5d6576120ce99c645a0e92d229f77d8564f2d9fea3b5a1f24510914c411` |
| `backend/groth16/bls12-381/mpcsetup/setup.go` | `4f49cb4e2dd16746f94371210b69a0a3d1020e39` | 3,831 | `e61eb9b26d9a641679936404187a484d7f3b6db3965abe646ca293fedf502038` |

## Load-bearing observations

- Phase 1 contributes and verifies `tau`, `alpha`, and `beta` updates.
- Commitment-aware Phase 2 contributes and verifies `delta` plus one `sigma`
  update and proof of knowledge per commitment group.
- Phase 2 checks each sigma across its G1 commitment bases and G2 sigma point.
- Key sealing sets each `GSigmaNeg` to the negated G2 sigma point.
- Key sealing sets Groth16 `gamma` to the standard BLS12-381 G2 generator;
  gamma is not a contributed Phase 2 secret in this suite.
- Phase 1 and Phase 2 accept separate beacon challenges. The bridge must provide
  distinct future beacons for Phase 1 and every per-circuit Phase 2 transcript.

This receipt establishes source identity and observed behavior. It does not
approve the fork, ceremony implementation, setup output, or deployed keys.
