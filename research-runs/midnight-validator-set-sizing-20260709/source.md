# Midnight validator-set sizing source pack

This source pack records deterministic extraction from public `midnight-node`
resource chain specs and permissioned-candidate configs.

## Govnet

Source: `_external/midnight-node/res/govnet/chain-spec-abridged.json`

Extraction count: govnet chain-spec-abridged: d=6/0 beefy=6 session=6 committee=6

Relevant direct excerpt:

```json
"beefy": {
  "authorities": [
    "KW8y7q7Pm5E6nd6mqBT4PWwnkokq3s1NFwo324CD6nAU83tfa",
    "KW7Ag2Qm7Boeq3qSYWrkUcKwsK4MtsKJJDfYWDQnyXbi8xZcQ",
    "KW4By7sGPMtFQiT58B3htoFupjBS4LQaLYvACpMSHyYFRPWV1",
    "KW7HSpvnLiHAaUy9MMpZQZE1cpNjDDPFreFxutkBv6orzy2Ye",
    "KW5YoAh4c4MTgAVQX9zKqFrakiEjdw1Udk5TtdSbGRyks7aGd",
    "KW9FvmfX2szgepSWKebPH43fKFycYW35yz8LkHkZLDt2DgWKd"
  ],
  "genesisBlock": 1
}
"dParameter": {
  "num_permissioned_candidates": 6,
  "num_registered_candidates": 0
}
```

## Devnet

Source: `_external/midnight-node/res/devnet/chain-spec-abridged.json`

Extraction count: devnet chain-spec-abridged: d=7/0 beefy=7 session=7 committee=7

Relevant direct excerpt:

```json
"beefy": {
  "authorities": [
    "KWBJCFSE2SZUiEhhTbL6vTW71WpABUXsBkAN6SCFdcub8Yz4W",
    "KWE4aogM7533QGnCcVbviF96x5Xs7cEwJQY4iocGQuWU3FDcn",
    "KWCCcbpNMY46M79KcwVvYKimntzCixbbAsPk9tCrT3H1w3n8R",
    "KW9cAQRoPXFxNyhUfCnJYc3gA3KPBoC5JLEyBo7i24a1nWSAM",
    "KW3SLTJQ82b4GKi4vjqTTr8YrfDoi9hdpjjZygGvmRWU8NiNU",
    "KW3JHdizpVr8HSMtwtFQZRgRepBmM9H831ABr8o96VXP4x2qj",
    "KW9HQ65ExPkW7GNBejwHHJGRWUN3G6L3wDH7GHuUEPUzC6st5"
  ],
  "genesisBlock": 1
}
"dParameter": {
  "num_permissioned_candidates": 7,
  "num_registered_candidates": 0
}
```

## Mainnet

Source: `_external/midnight-node/res/mainnet/chain-spec-abridged.json`

Extraction count: mainnet chain-spec-abridged: d=10/0 beefy=10 session=10 committee=10

Relevant direct excerpt:

```json
"beefy": {
  "authorities": [
    "KWDY43zYC5dQKFdJwK9hhFxTWNp1nAosgaPkEZnu4TP6LLPL2",
    "KW8mdGhCqLSpqTjzX3bfwmNC5V8Vc6Q3NNmU1c5b1wNjjAydg",
    "KW3XF77ofdEKvMypTEbQme9x6NUDSBtGqXomd9HjZbyi9FMUK",
    "KWD5Ux7t2Nz5BE4iVj6idDDPSd43vdwpnBdTdcQo9AtTZsYTR",
    "KWDkHpC1QjjwYGq3XE2q77ATU6PpS6fP8Kq2qFk5wxYrieZLG",
    "KW5BKKGfH1XgKjhyed4YLs8mvwG4qjYGgnnzNrubWXfhTqQVE",
    "KW59ZwUkED5BDhW2SibjsvY2B5gmTLuX5mbicnpXUCeKdYYZL",
    "KWBnsM947n7PNezzX9Y44dRsPdwUJeBwq2vHqBsWvNicwGhhH",
    "KWCL6NgGizNNrASDxr5sEXe1sJCsp4rTmoMoZzKkfT6e5HXf5",
    "KW9mGCzhtJeKCcUuabiinv7EjXGBanv9p9ieM9A2wDPhth3Xw"
  ],
  "genesisBlock": 1
}
"dParameter": {
  "num_permissioned_candidates": 10,
  "num_registered_candidates": 0
}
```

## Local

Source: `_external/midnight-node/res/local/permissioned-candidates-config.json`

Extraction count: local permissioned-candidates-config: 5

No `_external/midnight-node/res/local/chain-spec-abridged.json` file exists in this checkout.
