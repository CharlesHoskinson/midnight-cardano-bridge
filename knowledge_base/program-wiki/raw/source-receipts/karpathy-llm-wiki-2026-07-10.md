---
id: source.external.karpathy-llm-wiki.2026-07-10
type: source-receipt
retrieved_at: 2026-07-10T15:02:07Z
status: immutable-on-commit
---

# Karpathy LLM Wiki source receipt

URL: `https://gist.githubusercontent.com/karpathy/442a6bf555914893e9891c11519de94f/raw/llm-wiki.md`

Transport: Scrapling 0.4.10 `extract get --ai-targeted`

Retrieved bytes: 11992

SHA-256: `ef8342b7e7af711a6f1f36a989b6d546882fd913d310259572a897549582cd1f`

Principles adopted here:

- keep immutable raw sources separate from maintained synthesis;
- let a repository rule file define how agents maintain the wiki;
- update an index on every ingest;
- keep a chronological append-only log;
- file durable query results back into the wiki;
- lint contradictions, stale claims, orphans, missing concepts, and links;
- use plain Markdown and Git before adding retrieval infrastructure.
