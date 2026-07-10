# Proof bridge program wiki

This directory is the maintained design memory for the public-testnet proof
bridge program. It follows the LLM Wiki pattern: immutable source receipts feed
a maintained Markdown synthesis, and a repository rule file tells agents how to
ingest, query, and lint it.

The wiki does not replace the canonical bridge design, OpenSpec, source mirrors,
or executable evidence. It records how those materials relate, which decisions
are active, what superseded them, and which questions remain unresolved.

## Layout

```text
raw/       immutable design-session records and source receipts
wiki/      maintained pages, index, overview, open questions, and log
graph/     append-only graph events plus deterministic materialized views
reports/   lint and consistency reports
AGENTS.md  page schema and maintenance workflow
```

Read `wiki/index.md` first. Agents must read `AGENTS.md` before changing any file
under this directory.
