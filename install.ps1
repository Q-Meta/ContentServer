param(
    [string] $InstallDir = (Join-Path $env:LOCALAPPDATA "Programs\Dubnium.Mini"),
    [string] $Repo = "Q-Meta/ContentServer",
    [string] $Branch = "main",
    [switch] $SkipPath,
    [switch] $Force
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

function Write-Step {
    param([string] $Message)
    Write-Host "==> $Message"
}

function Add-UserPathEntry {
    param([Parameter(Mandatory = $true)][string] $PathEntry)

    $userPath = [Environment]::GetEnvironmentVariable("Path", "User")
    $entries = @()

    if (-not [string]::IsNullOrWhiteSpace($userPath)) {
        $entries = $userPath.Split(";", [System.StringSplitOptions]::RemoveEmptyEntries)
    }

    $normalizedEntry = [IO.Path]::GetFullPath($PathEntry).TrimEnd("\")
    $alreadyPresent = $entries | Where-Object {
        [IO.Path]::GetFullPath($_).TrimEnd("\") -ieq $normalizedEntry
    }

    if ($alreadyPresent) {
        return $false
    }

    $updatedPath = if ([string]::IsNullOrWhiteSpace($userPath)) {
        $normalizedEntry
    } else {
        "$userPath;$normalizedEntry"
    }

    [Environment]::SetEnvironmentVariable("Path", $updatedPath, "User")
    $env:Path = "$env:Path;$normalizedEntry"
    return $true
}

$baseUrl = "https://raw.githubusercontent.com/$Repo/$Branch/Boot"
$exeUrl = "$baseUrl/Dubnium.Mini.exe"
$licenseUrl = "$baseUrl/LICENSE"

$resolvedInstallDir = [IO.Path]::GetFullPath($InstallDir)
$exePath = Join-Path $resolvedInstallDir "Dubnium.Mini.exe"
$licensePath = Join-Path $resolvedInstallDir "LICENSE"

if ((Test-Path $resolvedInstallDir) -and -not $Force) {
    Write-Step "Using existing install directory: $resolvedInstallDir"
} else {
    Write-Step "Creating install directory: $resolvedInstallDir"
    New-Item -ItemType Directory -Path $resolvedInstallDir -Force | Out-Null
}

Write-Step "Downloading Dubnium.Mini.exe"
Invoke-WebRequest -Uri $exeUrl -OutFile $exePath -UseBasicParsing

Write-Step "Downloading LICENSE"
Invoke-WebRequest -Uri $licenseUrl -OutFile $licensePath -UseBasicParsing

if (-not $SkipPath) {
    if (Add-UserPathEntry -PathEntry $resolvedInstallDir) {
        Write-Step "Added install directory to the user PATH"
    } else {
        Write-Step "Install directory already exists in the user PATH"
    }
}

Write-Host ""
Write-Host "Dubnium.Mini installed to: $exePath"

if ($SkipPath) {
    Write-Host "Run it with: `"$exePath`""
} else {
    Write-Host "Open a new PowerShell window, then run: Dubnium.Mini.exe"
}
