[CmdletBinding(SupportsShouldProcess, ConfirmImpact = 'Medium')]
param()

$ErrorActionPreference = 'Stop'
Set-StrictMode -Version Latest

$repoRoot = (Resolve-Path (Join-Path $PSScriptRoot '..')).Path
$expectedVersions = [ordered]@{
    powershell = '7.6.3'
    cargo = '1.90.0'
    rustc = '1.90.0'
    go = '1.25.7'
    python = '3.14.6'
    node = '24.18.0'
    npm = '11.16.0'
    git = '2.55.0.windows.1'
    openspec = '1.5.0'
    scrapling = '0.4.10'
    cbor2 = '5.7.1'
}

function Resolve-Tool {
    param(
        [Parameter(Mandatory)] [string[]] $Names,
        [Parameter(Mandatory)] [string] $EnvironmentVariable,
        [string[]] $FallbackPaths = @()
    )

    $override = [Environment]::GetEnvironmentVariable($EnvironmentVariable)
    if ($override) {
        if (-not (Test-Path -LiteralPath $override -PathType Leaf)) {
            throw "$EnvironmentVariable does not name an executable file: $override"
        }
        return (Resolve-Path -LiteralPath $override).Path
    }
    foreach ($name in $Names) {
        $command = Get-Command $name -ErrorAction SilentlyContinue | Select-Object -First 1
        if ($command -and $command.Source) { return $command.Source }
    }
    foreach ($path in $FallbackPaths) {
        if ($path -and (Test-Path -LiteralPath $path -PathType Leaf)) {
            return (Resolve-Path -LiteralPath $path).Path
        }
    }
    throw "required tool not found: $($Names -join ', ') (override with $EnvironmentVariable)"
}

function Invoke-Captured {
    param(
        [Parameter(Mandatory)] [string] $Path,
        [string[]] $Arguments = @()
    )

    $output = & $Path @Arguments 2>&1
    if ($LASTEXITCODE -ne 0) {
        throw "command failed ($LASTEXITCODE): $Path $($Arguments -join ' ')"
    }
    return (($output | Out-String).Trim())
}

function Assert-Version {
    param(
        [Parameter(Mandatory)] [string] $Name,
        [Parameter(Mandatory)] [string] $Actual
    )

    $expected = $expectedVersions[$Name]
    if ($Actual -ne $expected) {
        throw "unsupported $Name version (expected=$expected actual=$Actual)"
    }
}

function Get-SemanticVersion {
    param(
        [Parameter(Mandatory)] [string] $Text,
        [Parameter(Mandatory)] [string] $Pattern,
        [Parameter(Mandatory)] [string] $Name
    )

    if ($Text -notmatch $Pattern) { throw "unrecognized $Name version: $Text" }
    return $Matches.version
}

function Get-LockedPythonPackages {
    param([Parameter(Mandatory)] [string] $Path)

    $packages = @{}
    foreach ($line in Get-Content -LiteralPath $Path) {
        $value = $line.Trim()
        if (-not $value -or $value.StartsWith('#')) { continue }
        if ($value -notmatch '^(?<name>[A-Za-z0-9][A-Za-z0-9._-]*)==(?<version>[^\s;]+)$') {
            throw "Python lock entry is not an exact name==version pin: $value"
        }
        $name = [regex]::Replace($Matches.name.ToLowerInvariant(), '[-_.]+', '-')
        if ($packages.ContainsKey($name)) { throw "duplicate normalized Python lock package: $name" }
        $packages[$name] = $Matches.version
    }
    $ordered = [ordered]@{}
    foreach ($name in @($packages.Keys | Sort-Object -CaseSensitive)) { $ordered[$name] = $packages[$name] }
    return $ordered
}

function Get-InstalledPythonPackages {
    param([Parameter(Mandatory)] [string] $Python)

    $code = @'
import importlib.metadata as metadata
import json
import re

versions = {}
for distribution in metadata.distributions():
    raw_name = distribution.metadata.get("Name")
    if raw_name:
        name = re.sub(r"[-_.]+", "-", raw_name.casefold())
        if name != "pip":
            versions[name] = distribution.version
print(json.dumps(dict(sorted(versions.items())), separators=(",", ":")))
'@
    return ((Invoke-Captured $Python @('-B', '-c', $code)) | ConvertFrom-Json)
}

function Assert-PythonLockMatch {
    param(
        [Parameter(Mandatory)] $Locked,
        [Parameter(Mandatory)] $Installed
    )

    $lockedJson = $Locked | ConvertTo-Json -Compress
    $installedJson = $Installed | ConvertTo-Json -Compress
    if ($installedJson -ne $lockedJson) {
        throw 'installed Python distributions do not exactly match requirements.lock.txt'
    }
}

function Invoke-SetupOperation {
    param(
        [Parameter(Mandatory)] [string] $Name,
        [Parameter(Mandatory)] [string] $Target,
        [Parameter(Mandatory)] [string] $Action,
        [Parameter(Mandatory)] [scriptblock] $Command
    )

    if ($PSCmdlet.ShouldProcess($Target, $Action)) {
        Write-Output "setup=$Name state=RUNNING"
        & $Command
        if ($LASTEXITCODE -ne 0) {
            throw "setup operation failed: $Name (exit $LASTEXITCODE)"
        }
        Write-Output "setup=$Name state=PASS"
    } else {
        Write-Output "setup=$Name state=PLANNED"
    }
}

try {
    Write-Output 'public_data_fetch=false'
    Write-Output 'dependency_registry_access=true'

    $tools = @{
        cargo = Resolve-Tool -Names @('cargo.exe', 'cargo') -EnvironmentVariable 'MCB_CARGO' -FallbackPaths @((Join-Path $HOME '.cargo\bin\cargo.exe'), (Join-Path $HOME '.cargo/bin/cargo'))
        rustc = Resolve-Tool -Names @('rustc.exe', 'rustc') -EnvironmentVariable 'MCB_RUSTC' -FallbackPaths @((Join-Path $HOME '.cargo\bin\rustc.exe'), (Join-Path $HOME '.cargo/bin/rustc'))
        go = Resolve-Tool -Names @('go.exe', 'go') -EnvironmentVariable 'MCB_GO' -FallbackPaths @((Join-Path $HOME '.local\toolchains\go1.25.7\go\bin\go.exe'), (Join-Path $HOME '.local/toolchains/go1.25.7/go/bin/go'))
        python = Resolve-Tool -Names @('python.exe', 'python') -EnvironmentVariable 'MCB_PYTHON'
        node = Resolve-Tool -Names @('node.exe', 'node') -EnvironmentVariable 'MCB_NODE'
        npm = Resolve-Tool -Names @('npm.cmd', 'npm') -EnvironmentVariable 'MCB_NPM'
        git = Resolve-Tool -Names @('git.exe', 'git') -EnvironmentVariable 'MCB_GIT'
    }

    $cargoVersion = Get-SemanticVersion -Text (Invoke-Captured $tools.cargo @('--version')) -Pattern '^cargo (?<version>\d+\.\d+\.\d+) ' -Name 'cargo'
    $rustcVersion = Get-SemanticVersion -Text (Invoke-Captured $tools.rustc @('--version')) -Pattern '^rustc (?<version>\d+\.\d+\.\d+) ' -Name 'rustc'
    $goVersion = Get-SemanticVersion -Text (Invoke-Captured $tools.go @('version')) -Pattern '^go version go(?<version>\d+\.\d+\.\d+) ' -Name 'go'
    $gitVersion = Get-SemanticVersion -Text (Invoke-Captured $tools.git @('--version')) -Pattern '^git version (?<version>\S+)$' -Name 'git'
    $versions = [ordered]@{
        powershell = $PSVersionTable.PSVersion.ToString()
        cargo = $cargoVersion
        rustc = $rustcVersion
        go = $goVersion
        python = Invoke-Captured $tools.python @('-B', '-c', 'import platform; print(platform.python_version())')
        node = (Invoke-Captured $tools.node @('--version')).TrimStart('v')
        npm = Invoke-Captured $tools.npm @('--version')
        git = $gitVersion
    }
    foreach ($name in $versions.Keys) { Assert-Version -Name $name -Actual $versions[$name] }
    Write-Output 'setup=tool-versions state=PASS'

    $requirements = Join-Path $repoRoot 'reference\observers\requirements.txt'
    $requirementsLock = Join-Path $repoRoot 'reference\observers\requirements.lock.txt'
    if (-not (Test-Path -LiteralPath $requirements -PathType Leaf)) {
        throw "pinned observer requirements are missing: $requirements"
    }
    $requiredPackages = @('scrapling[fetchers]==0.4.10', 'cbor2==5.7.1')
    $actualPackages = @(Get-Content -LiteralPath $requirements | ForEach-Object { $_.Trim() } | Where-Object { $_ })
    if (($actualPackages -join "`n") -ne ($requiredPackages -join "`n")) {
        throw "observer requirements must contain only the exact supported packages: $($requiredPackages -join ', ')"
    }
    if (-not (Test-Path -LiteralPath $requirementsLock -PathType Leaf)) {
        throw "Python transitive lock is missing: $requirementsLock"
    }
    $lockedPackages = Get-LockedPythonPackages -Path $requirementsLock
    foreach ($pin in @{'scrapling' = '0.4.10'; 'cbor2' = '5.7.1'}.GetEnumerator()) {
        if ($lockedPackages[$pin.Key] -ne $pin.Value) {
            throw "Python lock does not contain required top-level pin $($pin.Key)==$($pin.Value)"
        }
    }
    Write-Output 'setup=python-lock-validation state=PASS'
    $venv = Join-Path $repoRoot '.venv-scrapling'
    $venvPython = if ($IsWindows) {
        Join-Path $venv 'Scripts\python.exe'
    } else {
        Join-Path $venv 'bin/python'
    }

    Push-Location $repoRoot
    try {
        Invoke-SetupOperation -Name 'npm-ci' -Target $repoRoot -Action 'install exact Node dependencies from package-lock.json' -Command {
            & $tools.npm ci --ignore-scripts --no-audit --no-fund
        }
        Invoke-SetupOperation -Name 'python-venv' -Target $venv -Action 'create a clean Python virtual environment' -Command {
            & $tools.python -B -m venv --clear $venv
        }
        Invoke-SetupOperation -Name 'python-requirements' -Target $venv -Action 'install the exact transitive Python lock' -Command {
            & $venvPython -B -m pip install --disable-pip-version-check --no-input --requirement $requirementsLock
        }
        Invoke-SetupOperation -Name 'cargo-fetch-locked' -Target (Join-Path $repoRoot 'reference\rust\Cargo.lock') -Action 'fetch Rust dependencies without changing Cargo.lock' -Command {
            & $tools.cargo fetch --locked --manifest-path (Join-Path $repoRoot 'reference\rust\Cargo.toml')
        }
    } finally {
        Pop-Location
    }

    if (-not $WhatIfPreference) {
        $openspec = (Resolve-Path -LiteralPath (Join-Path $repoRoot 'node_modules\.bin\openspec.cmd') -ErrorAction Stop).Path
        Assert-Version -Name 'openspec' -Actual (Invoke-Captured $openspec @('--version'))
        Assert-Version -Name 'python' -Actual (Invoke-Captured $venvPython @('-B', '-c', 'import platform; print(platform.python_version())'))
        foreach ($package in @('scrapling', 'cbor2')) {
            $version = Invoke-Captured $venvPython @('-B', '-c', "import importlib.metadata as m; print(m.version('$package'))")
            Assert-Version -Name $package -Actual $version
        }
        Assert-PythonLockMatch -Locked $lockedPackages -Installed (Get-InstalledPythonPackages -Python $venvPython)
        Write-Output 'setup=python-lock-match state=PASS'
        Write-Output 'setup=installed-versions state=PASS'
    }

    Write-Output 'setup=reference-harness state=READY'
    exit 0
} catch {
    [Console]::Error.WriteLine("reference harness setup failed: $($_.Exception.Message)")
    exit 1
}
