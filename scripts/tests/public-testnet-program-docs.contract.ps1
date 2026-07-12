$ErrorActionPreference = 'Stop'
Set-StrictMode -Version Latest

$repoRoot = (Resolve-Path (Join-Path $PSScriptRoot '..\..')).Path

function Read-RepoText {
    param([Parameter(Mandatory)] [string] $RelativePath)
    return Get-Content -Raw -LiteralPath (Join-Path $repoRoot $RelativePath)
}

function Assert-Contains {
    param(
        [Parameter(Mandatory)] [string] $Text,
        [Parameter(Mandatory)] [string] $Value,
        [Parameter(Mandatory)] [string] $Label
    )
    if (-not $Text.Contains($Value)) { throw "$Label is missing required text: $Value" }
}

function Assert-NotMatches {
    param(
        [Parameter(Mandatory)] [string] $Text,
        [Parameter(Mandatory)] [string] $Pattern,
        [Parameter(Mandatory)] [string] $Label
    )
    if ($Text -match $Pattern) { throw "$Label contains prohibited pattern: $Pattern" }
}

function Get-ReentryContract {
    param(
        [Parameter(Mandatory)] [string] $Text,
        [Parameter(Mandatory)] [string] $Label
    )
    $match = [regex]::Match(
        $Text,
        '(?s)<!-- re-entry-contract:v2:start -->\r?\n(?<body>.*?)\r?\n<!-- re-entry-contract:v2:end -->'
    )
    if (-not $match.Success) { throw "$Label does not contain the re-entry contract block" }
    return ($match.Groups['body'].Value -replace "`r`n", "`n")
}

$master = Read-RepoText 'docs/superpowers/plans/2026-07-10-public-testnet-proof-bridge-program.md'
$s00 = Read-RepoText 'docs/superpowers/plans/2026-07-10-pbt-s00-program-control-plane.md'
$rebaseline = Read-RepoText 'docs/superpowers/specs/2026-07-10-public-testnet-proof-bridge-program-rebaseline-design.md'
$bridge = Read-RepoText 'knowledge_base/bridges/midnight-cardano-recursive-bridge.md'
$readme = Read-RepoText 'README.md'
$checklist = Read-RepoText 'EXAMINATION-CHECKLIST.md'
$researchPlan = Read-RepoText 'RESEARCH-PLAN.md'
$ceremony = Read-RepoText 'knowledge_base/proof-systems/groth16-trusted-setup-ceremony.md'
$mpcWiki = Read-RepoText 'knowledge_base/program-wiki/wiki/components/mpc-ceremony.md'
$controlWiki = Read-RepoText 'knowledge_base/program-wiki/wiki/components/program-control-plane.md'
$openQuestions = Read-RepoText 'knowledge_base/program-wiki/wiki/open-questions.md'
$sprintWiki = Read-RepoText 'knowledge_base/program-wiki/wiki/sprints/overview.md'
$overviewWiki = Read-RepoText 'knowledge_base/program-wiki/wiki/overview.md'
$indexWiki = Read-RepoText 'knowledge_base/program-wiki/wiki/index.md'
$fundamentals = Read-RepoText 'knowledge_base/proof-systems/proof-systems-fundamentals.md'
$zkPage = Read-RepoText 'knowledge_base/midnight/zero-knowledge-proofs.md'
$bootstrapReview = Read-RepoText 'docs/superpowers/reviews/2026-07-10-public-testnet-proof-bridge-implementation-plan-review.md'

$allPackageIds = @([regex]::Matches($master, 'PBT-S\d{2}-W\d{2}') | ForEach-Object Value | Sort-Object -Unique)
if ($allPackageIds.Count -ne 106) { throw "master package count is $($allPackageIds.Count), expected 106" }

$registerRows = @()
foreach ($line in @($master -split '\r?\n')) {
    if ($line -notmatch '^\| `(?<id>PBT-S\d{2}-W\d{2})` \|') { continue }
    $cells = @($line.Trim([char]'|').Split([char]'|') | ForEach-Object Trim)
    $dependencies = @([regex]::Matches($cells[2], 'PBT-S\d{2}-W\d{2}') | ForEach-Object Value | Sort-Object -Unique)
    $registerRows += [pscustomobject]@{ Id = $Matches['id']; Dependencies = $dependencies }
}
$packageIndex = @{}
for ($index = 0; $index -lt $registerRows.Count; $index++) { $packageIndex[$registerRows[$index].Id] = $index }
$dependencyCount = 0
foreach ($row in $registerRows) {
    foreach ($dependency in $row.Dependencies) {
        $dependencyCount++
        if (-not $packageIndex.ContainsKey($dependency)) { throw "unknown package dependency: $($row.Id) -> $dependency" }
        if ($packageIndex[$dependency] -ge $packageIndex[$row.Id]) { throw "register is not topologically ordered: $($row.Id) -> $dependency" }
    }
}
if ($dependencyCount -ne 231) { throw "master dependency count is $dependencyCount, expected 231" }
Assert-Contains -Text $master -Value '231 explicit dependency edges' -Label 'master plan quantification'

$s00Section = [regex]::Match($master, '(?s)### PBT-S00:.*?(?=### PBT-S01:)').Value
$w03RegisterRow = [regex]::Match($s00Section, '(?m)^\| `PBT-S00-W03`.*$').Value
$w13RegisterRow = [regex]::Match($s00Section, '(?m)^\| `PBT-S00-W13`.*$').Value
Assert-NotMatches -Text $w03RegisterRow -Pattern 'request, identity, and capability schemas' -Label 'W03 register ownership'
Assert-Contains -Text $w13RegisterRow -Value 'request, identity, and capability schemas' -Label 'W13 register ownership'
$s00Ids = @([regex]::Matches($s00Section, 'PBT-S00-W\d{2}') | ForEach-Object Value | Sort-Object -Unique)
$expectedS00 = @(1..18 | ForEach-Object { 'PBT-S00-W{0:D2}' -f $_ })
if (@(Compare-Object $expectedS00 $s00Ids).Count -ne 0) {
    throw "Sprint 0 package ids differ (actual=$($s00Ids -join ','))"
}

$s00TaskIds = @([regex]::Matches($s00, '^### Task \d+: `(?<id>PBT-S00-W\d{2})`', 'Multiline') | ForEach-Object { $_.Groups['id'].Value })
if ($s00TaskIds.Count -ne 18 -or (@($s00TaskIds | Sort-Object -Unique).Count -ne 18)) {
    throw "Sprint 0 implementation plan has $($s00TaskIds.Count) task ids, expected 18 unique ids"
}

foreach ($requiredTitle in @(
    '`PBT-S00-W03` Define Append-Only Events and Deterministic State Reduction',
    '`PBT-S00-W13` Implement Privileged Repository and Credential Methods',
    '`PBT-S00-W14` Reproduce, Qualify, and Provision the Controller Build',
    '`PBT-S00-W05` Implement the Universal Command Supervisor',
    '`PBT-S00-W15` Implement Transaction and Pack Quarantine',
    '`PBT-S00-W16` Close Bootstrap and Publish the Package Entrypoint',
    '`PBT-S00-W12` Publish and Reproduce the Base GateRosterV2',
    '`PBT-S00-W17` Integrate CI and Run the Control-Plane Smoke Test',
    '`PBT-S00-W18` Close Sprint 0 and Confirm Remote Publication'
)) {
    $masterTableEntry = $requiredTitle -replace '^(`PBT-S00-W\d{2}`) ', '| $1 | '
    Assert-Contains -Text $master -Value $masterTableEntry -Label 'master plan'
    Assert-Contains -Text $s00 -Value $requiredTitle -Label 'Sprint 0 plan'
}

$reentryMaster = Get-ReentryContract -Text $master -Label 'master plan'
$reentryS00 = Get-ReentryContract -Text $s00 -Label 'Sprint 0 plan'
$reentryRebaseline = Get-ReentryContract -Text $rebaseline -Label 'rebaseline design'
if ($reentryMaster -cne $reentryS00 -or $reentryMaster -cne $reentryRebaseline) {
    throw 're-entry contract blocks are not byte-identical after newline normalization'
}
foreach ($requiredReentry in @(
    'deployed-copy or ABI-observation drift',
    '`PBT-S11`',
    'endpoint-only drift',
    'network identity, official-root, finality, or runtime-semantic drift'
)) {
    Assert-Contains -Text $reentryMaster -Value $requiredReentry -Label 're-entry contract'
}

foreach ($text in @($master, $s00, $rebaseline)) {
    Assert-Contains -Text $text -Value 'Reader outputs are advisory quality evidence and never a closure input.' -Label 'program authority text'
    Assert-NotMatches -Text $text -Pattern 'readers report 0/0/0' -Label 'program authority text'
}
foreach ($pattern in @(
    'Only endpoint-only drift',
    'Closure requires all three counts to be zero',
    'closing W01-W12',
    '100 canonical package nodes',
    '100 package nodes',
    'direct closure and classifier inputs',
    'missing or nonzero PBT-S13 review artifacts',
    'nonzero reader count'
)) {
    Assert-NotMatches -Text $s00 -Pattern $pattern -Label 'Sprint 0 authority text'
}
Assert-NotMatches -Text $master -Pattern 'pending direct closure inputs' -Label 'master review authority'
Assert-NotMatches -Text $rebaseline -Pattern 'Fresh reviews pass the frozen public snapshot' -Label 'rebaseline review authority'
Assert-NotMatches -Text $rebaseline -Pattern 'all fresh readers pass one program snapshot' -Label 'rebaseline Sprint 1 exit gate'
Assert-NotMatches -Text $bridge -Pattern 'direct PBT-S13 Codex, council, and disposition inputs' -Label 'canonical classifier authority'
Assert-NotMatches -Text $bridge -Pattern 'zero-count final reviews' -Label 'canonical classifier authority'
Assert-NotMatches -Text $bridge -Pattern 'required PBT-S13 review' -Label 'canonical classifier authority'
Assert-NotMatches -Text $bridge -Pattern 'planning baseline through the committed W05 supervisor' -Label 'canonical bootstrap boundary'
Assert-Contains -Text $bridge -Value 'planning baseline through the committed W16 entrypoint' -Label 'canonical bootstrap boundary'
Assert-NotMatches -Text $readme -Pattern 'reports zero Blocking and zero unresolved Major findings' -Label 'README closure authority'

Assert-Contains -Text $s00 -Value 'ProgramBaselinePrecommitmentV1' -Label 'Sprint 0 plan'
Assert-Contains -Text $s00 -Value 'MCB_PBT_S00_BASELINE_PRECOMMITMENT' -Label 'Sprint 0 plan'
Assert-Contains -Text $s00 -Value 'program/schemas/classifier-readiness-v1.schema.json' -Label 'Sprint 0 plan'
Assert-Contains -Text $master -Value 'redaction receipts' -Label 'master ClosureEnvelopeV1'
Assert-Contains -Text $rebaseline -Value 'redaction receipts' -Label 'rebaseline ClosureEnvelopeV1'

Assert-NotMatches -Text $bridge -Pattern 'The proof of concept uses approved checkpoint manifests' -Label 'canonical bridge design'
Assert-Contains -Text $bridge -Value 'official-root-derived acceleration checkpoint' -Label 'canonical bridge design'
Assert-Contains -Text $bridge -Value 'approval_policy_digest' -Label 'ArtifactAuthorizationV1'
Assert-NotMatches -Text $bridge -Pattern 'source-dependent Sprint 3 gate' -Label 'canonical bridge design'
Assert-Contains -Text $bridge -Value 'PBT-S04-W01' -Label 'canonical bridge design'
Assert-NotMatches -Text $bridge -Pattern 'Midnight genesis or checkpoint' -Label 'canonical bridge trust table'
Assert-NotMatches -Text $bridge -Pattern 'checkpoint approval, the independent Mithril genesis key' -Label 'canonical bridge trust summary'

foreach ($text in @($master, $rebaseline, $mpcWiki)) {
    Assert-Contains -Text $text -Value 'ContributorIndependencePolicyV1' -Label 'contributor independence policy'
}
Assert-Contains -Text $mpcWiki -Value 'failure conditions' -Label 'contributor independence policy'

foreach ($pair in @(
    @{ Label = 'README'; Text = $readme },
    @{ Label = 'EXAMINATION-CHECKLIST'; Text = $checklist },
    @{ Label = 'RESEARCH-PLAN'; Text = $researchPlan }
)) {
    Assert-NotMatches -Text $pair.Text -Pattern 'degraded-lab' -Label $pair.Label
    Assert-NotMatches -Text $pair.Text -Pattern '11[- ]sprint' -Label $pair.Label
    Assert-NotMatches -Text $pair.Text -Pattern '§3[0-9]' -Label $pair.Label
}
Assert-Contains -Text $readme -Value '14-sprint, 106-package' -Label 'README'
Assert-Contains -Text $bootstrapReview -Value 'Classification: pre-control-plane bootstrap review' -Label 'historical plan review'
Assert-Contains -Text $bootstrapReview -Value 'does not authorize Sprint 0' -Label 'historical plan review'
Assert-NotMatches -Text $bootstrapReview -Pattern '^\*\*Source baseline:\*\*' -Label 'historical plan review'

if ($fundamentals -notmatch '(?m)^title: [''"].+[''"]$') {
    throw 'proof-system fundamentals title is not quoted YAML'
}
Assert-Contains -Text $ceremony -Value 'No bridge ceremony has run.' -Label 'ceremony concept'
Assert-Contains -Text $ceremony -Value 'new-or-update' -Label 'ceremony beacon mode'
Assert-Contains -Text $ceremony -Value 'Groth16 Phase 1 (Powers of Tau)' -Label 'ceremony terminology'
Assert-Contains -Text $ceremony -Value 'commitment-aware (BSB22) Phase 2' -Label 'ceremony terminology'
Assert-NotMatches -Text $ceremony -Pattern 'reusable BSB22 Phase 1' -Label 'ceremony terminology'
Assert-NotMatches -Text $zkPage -Pattern 'recursive, trustless\s+Midnight' -Label 'Midnight zero-knowledge page'
Assert-Contains -Text $zkPage -Value 'Specific implementation sources also resolve recursion' -Label 'Midnight zero-knowledge page'

Assert-NotMatches -Text $openQuestions -Pattern '(?m)^\s+- risk\.public-chain-gates\s*$' -Label 'open questions sources'
Assert-Contains -Text $openQuestions -Value 'Compact, cardano-node, and cardano-cli' -Label 'open questions'
Assert-Contains -Text $openQuestions -Value 'Midnight genesis and BEEFY data' -Label 'open questions'
Assert-Contains -Text $controlWiki -Value 'will be implemented by the 18 packages' -Label 'control-plane wiki'
Assert-Contains -Text $sprintWiki -Value '| PBT-S00 | 18 |' -Label 'sprint wiki'
Assert-Contains -Text $sprintWiki -Value '| Total | 106 |' -Label 'sprint wiki'
Assert-Contains -Text $overviewWiki -Value '14 sprints and 106 work packages' -Label 'overview wiki'
Assert-Contains -Text $indexWiki -Value '14-sprint, 106-package structure' -Label 'index wiki'

$nodesDocument = Get-Content -Raw -LiteralPath (Join-Path $repoRoot 'knowledge_base\program-wiki\graph\nodes.json') | ConvertFrom-Json
$edgesDocument = Get-Content -Raw -LiteralPath (Join-Path $repoRoot 'knowledge_base\program-wiki\graph\edges.json') | ConvertFrom-Json
$events = @(Get-Content -LiteralPath (Join-Path $repoRoot 'knowledge_base\program-wiki\graph\events.jsonl') | ForEach-Object { $_ | ConvertFrom-Json })
$packageNodes = @($nodesDocument.nodes | Where-Object type -eq 'package')
$s00Edges = @($edgesDocument.edges | Where-Object { $_.predicate -eq 'part-of' -and $_.object -eq 'sprint.pbt-s00' })
$programNode = @($nodesDocument.nodes | Where-Object id -eq 'program.public-testnet-proof-bridge')
if ($packageNodes.Count -ne 106) { throw "graph has $($packageNodes.Count) package nodes, expected 106" }
if ($s00Edges.Count -ne 18) { throw "graph has $($s00Edges.Count) Sprint 0 package edges, expected 18" }
if ($programNode.Count -ne 1 -or $programNode[0].package_count -ne 106) { throw 'program graph node package_count is not 106' }

for ($index = 0; $index -lt $events.Count; $index++) {
    $expectedSequence = $index + 1
    if ($events[$index].sequence -ne $expectedSequence -or $events[$index].event_id -ne ('kge-{0:D4}' -f $expectedSequence)) {
        throw "graph event sequence mismatch at index $index"
    }
}
$contradictions = @($events | Where-Object operation -eq 'contradict')
if ($contradictions.Count -ne 4) { throw "graph has $($contradictions.Count) contradiction events, expected 4" }

$eventNodeIds = @($events | Where-Object operation -eq 'add-node' | ForEach-Object subject | Sort-Object -Unique)
$viewNodeIds = @($nodesDocument.nodes | ForEach-Object id | Sort-Object -Unique)
if (@(Compare-Object $eventNodeIds $viewNodeIds).Count -ne 0) { throw 'node view does not materialize add-node events exactly' }
$eventEdges = @($events | Where-Object operation -eq 'add-edge' | ForEach-Object { '{0}|{1}|{2}' -f $_.subject,$_.predicate,$_.object } | Sort-Object -Unique)
$viewEdges = @($edgesDocument.edges | ForEach-Object { '{0}|{1}|{2}' -f $_.subject,$_.predicate,$_.object } | Sort-Object -Unique)
if (@(Compare-Object $eventEdges $viewEdges).Count -ne 0) { throw 'edge view does not materialize add-edge events exactly' }
if ($nodesDocument.generated_from.event_count -ne $events.Count -or $edgesDocument.generated_from.event_count -ne $events.Count) {
    throw 'materialized view event counts do not match the event log'
}
if ($nodesDocument.generated_from.last_event_id -ne $events[-1].event_id -or $edgesDocument.generated_from.last_event_id -ne $events[-1].event_id) {
    throw 'materialized view heads do not match the event log'
}
$packageCountEvents = @($events | Where-Object { $_.subject -eq 'program.public-testnet-proof-bridge' -and $_.predicate -eq 'package-count' })
if ($packageCountEvents[-1].object -ne '106') { throw 'latest package-count event does not supersede the old count with 106' }

foreach ($event in @($events | Where-Object sequence -ge 274)) {
    $sourcePath = Join-Path (Join-Path $repoRoot 'knowledge_base\program-wiki') $event.source_path
    if (-not (Test-Path -LiteralPath $sourcePath -PathType Leaf)) { throw "event source does not exist: $($event.event_id)" }
    $actualSourceHash = (Get-FileHash -LiteralPath $sourcePath -Algorithm SHA256).Hash.ToLowerInvariant()
    if ($actualSourceHash -cne $event.source_sha256) { throw "event source hash mismatch: $($event.event_id)" }
    $relativeSourcePath = [IO.Path]::GetRelativePath($repoRoot, $sourcePath).Replace('\', '/')
    $filteredOid = (& git -C $repoRoot hash-object --path=$relativeSourcePath -- $relativeSourcePath).Trim()
    $rawOid = (& git -C $repoRoot hash-object --no-filters -- $relativeSourcePath).Trim()
    if ($LASTEXITCODE -ne 0 -or $filteredOid -cne $rawOid) { throw "event source is not canonical LF bytes: $($event.event_id)" }
}

foreach ($receipt in @(
    'knowledge_base/program-wiki/raw/source-receipts/gnark-bsb22-mpc-2026-07-12.md',
    'knowledge_base/program-wiki/raw/source-receipts/proof-zk-recovery-mpc-2026-07-12.md'
)) {
    if (-not (Test-Path -LiteralPath (Join-Path $repoRoot $receipt) -PathType Leaf)) {
        throw "missing superseding source receipt: $receipt"
    }
}

Write-Output 'public-testnet-program-docs-contract: PASS'
