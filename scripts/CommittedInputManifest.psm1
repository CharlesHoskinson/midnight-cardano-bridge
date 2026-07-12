Set-StrictMode -Version Latest

function Invoke-GitRaw {
    param(
        [Parameter(Mandatory)] [string] $GitPath,
        [Parameter(Mandatory)] [string] $RepositoryRoot,
        [Parameter(Mandatory)] [string[]] $Arguments
    )

    $startInfo = [Diagnostics.ProcessStartInfo]::new()
    $startInfo.FileName = $GitPath
    $startInfo.UseShellExecute = $false
    $startInfo.RedirectStandardOutput = $true
    $startInfo.RedirectStandardError = $true
    $startInfo.CreateNoWindow = $true
    $startInfo.ArgumentList.Add('-C')
    $startInfo.ArgumentList.Add($RepositoryRoot)
    foreach ($argument in $Arguments) { $startInfo.ArgumentList.Add($argument) }

    $process = [Diagnostics.Process]::new()
    $process.StartInfo = $startInfo
    if (-not $process.Start()) { throw "could not start git: $GitPath" }

    $stdout = [IO.MemoryStream]::new()
    $stdoutCopy = $process.StandardOutput.BaseStream.CopyToAsync($stdout)
    $stderrRead = $process.StandardError.ReadToEndAsync()
    $process.WaitForExit()
    $null = $stdoutCopy.GetAwaiter().GetResult()
    $stderr = $stderrRead.GetAwaiter().GetResult()
    $exitCode = $process.ExitCode
    $process.Dispose()

    if ($exitCode -ne 0) {
        throw "git failed ($exitCode): git $($Arguments -join ' ')`n$($stderr.Trim())"
    }
    return [pscustomobject]@{
        Bytes = [byte[]]$stdout.ToArray()
    }
}

function Invoke-GitText {
    param(
        [Parameter(Mandatory)] [string] $GitPath,
        [Parameter(Mandatory)] [string] $RepositoryRoot,
        [Parameter(Mandatory)] [string[]] $Arguments
    )
    $result = Invoke-GitRaw -GitPath $GitPath -RepositoryRoot $RepositoryRoot -Arguments $Arguments
    return [Text.Encoding]::UTF8.GetString($result.Bytes).Trim()
}

function Split-NulUtf8 {
    param([Parameter(Mandatory)] [AllowEmptyCollection()] [byte[]] $Bytes)
    if ($Bytes.Length -eq 0) { return @() }
    return @(
        [Text.Encoding]::UTF8.GetString($Bytes).Split(
            [char]0,
            [StringSplitOptions]::RemoveEmptyEntries
        )
    )
}

function Get-CommittedInputManifest {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)] [string] $RepositoryRoot,
        [Parameter(Mandatory)] [string] $GitPath,
        [Parameter(Mandatory)] [string] $Snapshot,
        [Parameter(Mandatory)] [string[]] $Pathspec,
        [string] $ExcludePattern = '(^|/)target/|(^|/)__pycache__/|\.py[co]$'
    )

    $root = (Resolve-Path -LiteralPath $RepositoryRoot -ErrorAction Stop).Path
    if (-not (Test-Path -LiteralPath $GitPath -PathType Leaf)) {
        throw "git executable is missing: $GitPath"
    }
    if ($Pathspec.Count -eq 0) { throw 'at least one input pathspec is required' }
    foreach ($item in $Pathspec) {
        if ([IO.Path]::IsPathRooted($item) -or $item -match '(^|[\\/])\.\.([\\/]|$)') {
            throw "unsafe input pathspec: $item"
        }
    }

    $resolvedSnapshot = Invoke-GitText -GitPath $GitPath -RepositoryRoot $root -Arguments @('rev-parse', "$Snapshot^{commit}")
    if ($resolvedSnapshot -notmatch '^[0-9a-f]{40}$') {
        throw "snapshot did not resolve to a commit: $Snapshot"
    }

    & $GitPath -C $root diff --quiet --no-ext-diff $resolvedSnapshot -- @Pathspec
    if ($LASTEXITCODE -eq 1) { throw "tracked input differs from snapshot $resolvedSnapshot" }
    if ($LASTEXITCODE -ne 0) { throw "git diff failed while checking snapshot inputs (exit=$LASTEXITCODE)" }

    $untrackedArguments = @('ls-files', '--others', '--exclude-standard', '-z', '--') + $Pathspec
    $untrackedResult = Invoke-GitRaw -GitPath $GitPath -RepositoryRoot $root -Arguments $untrackedArguments
    $ignoredArguments = @('ls-files', '--others', '--ignored', '--exclude-standard', '-z', '--') + $Pathspec
    $ignoredResult = Invoke-GitRaw -GitPath $GitPath -RepositoryRoot $root -Arguments $ignoredArguments
    $untracked = @(
        @(
            Split-NulUtf8 -Bytes $untrackedResult.Bytes
            Split-NulUtf8 -Bytes $ignoredResult.Bytes
        ) |
            Where-Object { $_ -notmatch $ExcludePattern } |
            Sort-Object -CaseSensitive -Unique
    )
    if ($untracked.Count -gt 0) {
        throw "untracked input path: $($untracked[0])"
    }

    $treeArguments = @('ls-tree', '-r', '--name-only', '-z', $resolvedSnapshot, '--') + $Pathspec
    $treeResult = Invoke-GitRaw -GitPath $GitPath -RepositoryRoot $root -Arguments $treeArguments
    $paths = @(Split-NulUtf8 -Bytes $treeResult.Bytes | Where-Object { $_ -notmatch $ExcludePattern } | Sort-Object -CaseSensitive -Unique)
    if ($paths.Count -eq 0) { throw "snapshot contains no files for pathspec: $($Pathspec -join ', ')" }

    $manifest = [ordered]@{}
    foreach ($path in $paths) {
        $blobId = Invoke-GitText -GitPath $GitPath -RepositoryRoot $root -Arguments @('rev-parse', "$resolvedSnapshot`:$path")
        if ($blobId -notmatch '^[0-9a-f]{40}$') { throw "invalid blob id for input: $path" }
        $blobResult = Invoke-GitRaw -GitPath $GitPath -RepositoryRoot $root -Arguments @('cat-file', 'blob', $blobId)
        $manifest[$path] = [Convert]::ToHexString(
            [Security.Cryptography.SHA256]::HashData($blobResult.Bytes)
        ).ToLowerInvariant()
    }
    return $manifest
}

Export-ModuleMember -Function Get-CommittedInputManifest
