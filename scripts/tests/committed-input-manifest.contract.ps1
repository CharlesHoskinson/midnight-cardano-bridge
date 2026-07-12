$ErrorActionPreference = 'Stop'
Set-StrictMode -Version Latest

$repoRoot = (Resolve-Path (Join-Path $PSScriptRoot '..\..')).Path
$modulePath = Join-Path $repoRoot 'scripts\CommittedInputManifest.psm1'
if (-not (Test-Path -LiteralPath $modulePath -PathType Leaf)) {
    throw "committed-input manifest module is missing: $modulePath"
}

Import-Module $modulePath -Force
$attributesPath = Join-Path $repoRoot '.gitattributes'
if (-not (Test-Path -LiteralPath $attributesPath -PathType Leaf)) {
    throw 'repository LF checkout policy is missing: .gitattributes'
}
$attributes = (Get-Content -Raw -LiteralPath $attributesPath) -replace "`r`n", "`n"
if ($attributes -ne "* text=auto eol=lf`n") {
    throw 'repository LF checkout policy must be exactly: * text=auto eol=lf'
}
$verifierSource = Get-Content -Raw -LiteralPath (Join-Path $repoRoot 'scripts\verify-reference-harness.ps1')
foreach ($requiredPathspec in @("'.gitattributes'", "'reference/evidence/bootstrap'")) {
    if (-not $verifierSource.Contains($requiredPathspec, [StringComparison]::Ordinal)) {
        throw "reference verifier input manifest omits $requiredPathspec"
    }
}
$git = (Get-Command git -ErrorAction Stop).Source
$fixtureRoot = Join-Path ([IO.Path]::GetTempPath()) ("mcb-input-manifest-{0}" -f [guid]::NewGuid().ToString('N'))
$inputDirectory = Join-Path $fixtureRoot 'inputs'

function Invoke-Git {
    param([Parameter(ValueFromRemainingArguments)] [string[]] $Arguments)
    $output = & $git -C $fixtureRoot @Arguments 2>&1
    if ($LASTEXITCODE -ne 0) {
        throw "git failed ($LASTEXITCODE): git $($Arguments -join ' ')`n$($output -join "`n")"
    }
    return @($output)
}

function Assert-ThrowsLike {
    param(
        [Parameter(Mandatory)] [scriptblock] $Action,
        [Parameter(Mandatory)] [string] $Pattern
    )
    try {
        & $Action
    } catch {
        if ($_.Exception.Message -notlike $Pattern) {
            throw "unexpected error: $($_.Exception.Message)"
        }
        return
    }
    throw "expected error matching: $Pattern"
}

try {
    New-Item -ItemType Directory -Path $inputDirectory -Force | Out-Null
    $null = Invoke-Git init
    $null = Invoke-Git config core.autocrlf true

    $samplePath = Join-Path $inputDirectory 'sample.txt'
    $lfBytes = [Text.UTF8Encoding]::new($false).GetBytes("alpha`nbeta`n")
    [IO.File]::WriteAllBytes($samplePath, $lfBytes)
    $null = Invoke-Git add -- inputs/sample.txt
    $null = Invoke-Git -c user.name=contract -c user.email=contract@example.invalid commit -m baseline

    Remove-Item -LiteralPath $samplePath -Force
    $null = Invoke-Git checkout HEAD -- inputs/sample.txt
    $workingBytes = [IO.File]::ReadAllBytes($samplePath)
    if (-not [Text.Encoding]::UTF8.GetString($workingBytes).Contains("`r`n")) {
        throw 'fixture did not materialize CRLF checkout bytes'
    }

    $expectedBlobSha256 = [Convert]::ToHexString(
        [Security.Cryptography.SHA256]::HashData($lfBytes)
    ).ToLowerInvariant()
    $workingSha256 = (Get-FileHash -Algorithm SHA256 -LiteralPath $samplePath).Hash.ToLowerInvariant()
    if ($workingSha256 -eq $expectedBlobSha256) {
        throw 'fixture working bytes unexpectedly equal committed LF bytes'
    }

    $manifest = Get-CommittedInputManifest `
        -RepositoryRoot $fixtureRoot `
        -GitPath $git `
        -Snapshot HEAD `
        -Pathspec @('inputs')
    if ($manifest['inputs/sample.txt'] -ne $expectedBlobSha256) {
        throw "manifest did not hash committed blob bytes (expected=$expectedBlobSha256 actual=$($manifest['inputs/sample.txt']))"
    }

    Add-Content -LiteralPath $samplePath -Value 'semantic-change'
    Assert-ThrowsLike -Pattern '*tracked input differs from snapshot*' -Action {
        $null = Get-CommittedInputManifest -RepositoryRoot $fixtureRoot -GitPath $git -Snapshot HEAD -Pathspec @('inputs')
    }
    $null = Invoke-Git checkout HEAD -- inputs/sample.txt

    [IO.File]::WriteAllText(
        (Join-Path $inputDirectory 'untracked.txt'),
        "untracked`n",
        [Text.UTF8Encoding]::new($false)
    )
    Assert-ThrowsLike -Pattern '*untracked input path*' -Action {
        $null = Get-CommittedInputManifest -RepositoryRoot $fixtureRoot -GitPath $git -Snapshot HEAD -Pathspec @('inputs')
    }
    Remove-Item -LiteralPath (Join-Path $inputDirectory 'untracked.txt') -Force

    [IO.File]::WriteAllText(
        (Join-Path $fixtureRoot '.gitignore'),
        "inputs/*.pyd`n",
        [Text.UTF8Encoding]::new($false)
    )
    [IO.File]::WriteAllBytes((Join-Path $inputDirectory 'native.pyd'), [byte[]](1, 2, 3, 4))
    Assert-ThrowsLike -Pattern '*untracked input path*' -Action {
        $null = Get-CommittedInputManifest -RepositoryRoot $fixtureRoot -GitPath $git -Snapshot HEAD -Pathspec @('inputs')
    }

    Write-Output 'committed-input-manifest-contract: PASS'
} finally {
    if (Test-Path -LiteralPath $fixtureRoot) {
        $resolvedFixture = [IO.Path]::GetFullPath($fixtureRoot)
        $resolvedTemp = [IO.Path]::GetFullPath([IO.Path]::GetTempPath()).TrimEnd('\', '/')
        if (-not $resolvedFixture.StartsWith($resolvedTemp + [IO.Path]::DirectorySeparatorChar, [StringComparison]::OrdinalIgnoreCase)) {
            throw "refusing to remove fixture outside TEMP: $resolvedFixture"
        }
        Remove-Item -LiteralPath $resolvedFixture -Recurse -Force
    }
}
