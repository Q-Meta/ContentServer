param(
    [string] $InstallDir = (Join-Path $env:LOCALAPPDATA "Programs\Dubnium.Mini"),
    [switch] $SkipPath
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

function Write-Step {
    param([string] $Message)
    Write-Host "==> $Message"
}

function Remove-UserPathEntry {
    param([Parameter(Mandatory = $true)][string] $PathEntry)

    $userPath = [Environment]::GetEnvironmentVariable("Path", "User")
    if ([string]::IsNullOrWhiteSpace($userPath)) {
        return $false
    }

    $normalizedEntry = [IO.Path]::GetFullPath($PathEntry).TrimEnd("\")
    $entries = $userPath.Split(";", [System.StringSplitOptions]::RemoveEmptyEntries)

    $remainingEntries = @(
        $entries | Where-Object {
            [IO.Path]::GetFullPath($_).TrimEnd("\") -ine $normalizedEntry
        }
    )

    if ($remainingEntries.Count -eq $entries.Count) {
        return $false
    }

    $updatedPath = ($remainingEntries -join ";")
    [Environment]::SetEnvironmentVariable("Path", $updatedPath, "User")
    $env:Path = (($env:Path.Split(";", [System.StringSplitOptions]::RemoveEmptyEntries) | Where-Object {
        [IO.Path]::GetFullPath($_).TrimEnd("\") -ine $normalizedEntry
    }) -join ";")

    return $true
}

$resolvedInstallDir = [IO.Path]::GetFullPath($InstallDir)

if (Test-Path -LiteralPath $resolvedInstallDir) {
    Write-Step "Removing install directory: $resolvedInstallDir"
    Remove-Item -LiteralPath $resolvedInstallDir -Recurse -Force
} else {
    Write-Step "Install directory does not exist: $resolvedInstallDir"
}

if (-not $SkipPath) {
    if (Remove-UserPathEntry -PathEntry $resolvedInstallDir) {
        Write-Step "Removed install directory from the user PATH"
    } else {
        Write-Step "Install directory was not present in the user PATH"
    }
}

Write-Host ""
Write-Host "Dubnium.Mini uninstalled."
