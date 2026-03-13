# Fetch all .vsd files from Bitbucket Server and convert them locally
# Usage: .\fetch_and_convert.ps1 [-Token <personal-access-token>] [-Format <pdf|svg|png>]

param(
    [string]$Token,
    [ValidateSet("pdf", "svg", "png")]
    [string]$Format = "pdf",
    [string]$OutputFolder = (Join-Path $PSScriptRoot "VSD_scripts")
)

$ErrorActionPreference = "Stop"

# Bitbucket Server config
$BitbucketBase = "https://bitbucket.srv.westpac.com.au"
$Project       = "A006B2_1"
$Repo          = "au.com.westpac.ddep.apps.ude.automation"
$RepoPath      = "src/impactassessment_poc"
$Branch        = "feature/UA-3-ImpactAssessmentPOC"

# --- Auth header ---
$headers = @{}
if ($Token) {
    $headers["Authorization"] = "Bearer $Token"
} else {
    # Prompt for credentials if no token provided
    $cred = Get-Credential -Message "Enter your Bitbucket Server credentials"
    $pair = "$($cred.UserName):$($cred.GetNetworkCredential().Password)"
    $bytes = [System.Text.Encoding]::ASCII.GetBytes($pair)
    $headers["Authorization"] = "Basic $([Convert]::ToBase64String($bytes))"
}

# --- TLS setup (corporate environments) ---
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12

# --- List all files under the repo path recursively ---
Write-Host "Fetching file list from Bitbucket..." -ForegroundColor Cyan

$vsdFiles = @()
$start = 0
$isLastPage = $false

while (-not $isLastPage) {
    $listUrl = "$BitbucketBase/rest/api/1.0/projects/$Project/repos/$Repo/files/$RepoPath`?at=$Branch&limit=1000&start=$start"
    try {
        $response = Invoke-RestMethod -Uri $listUrl -Headers $headers -Method Get
    } catch {
        Write-Host "ERROR: Failed to list files from Bitbucket. Check your credentials and URL." -ForegroundColor Red
        Write-Host "  URL: $listUrl" -ForegroundColor Yellow
        Write-Host "  Error: $_" -ForegroundColor Red
        exit 1
    }

    foreach ($filePath in $response.values) {
        if ($filePath -match '\.vsd$') {
            $vsdFiles += $filePath
        }
    }

    $isLastPage = $response.isLastPage
    if (-not $isLastPage) {
        $start = $response.nextPageStart
    }
}

if ($vsdFiles.Count -eq 0) {
    Write-Host "No .vsd files found in '$RepoPath' on branch '$Branch'." -ForegroundColor Yellow
    exit
}

Write-Host "Found $($vsdFiles.Count) .vsd file(s):" -ForegroundColor Green
$vsdFiles | ForEach-Object { Write-Host "  $_" }

# --- Download each .vsd file ---
if (-not (Test-Path $OutputFolder)) {
    New-Item -ItemType Directory -Path $OutputFolder -Force | Out-Null
}

$downloadCount = 0
foreach ($filePath in $vsdFiles) {
    $rawUrl = "$BitbucketBase/rest/api/1.0/projects/$Project/repos/$Repo/raw/$RepoPath/$filePath`?at=$Branch"
    $fileName = Split-Path $filePath -Leaf
    $destPath = Join-Path $OutputFolder $fileName

    Write-Host "Downloading: $fileName ..." -NoNewline
    try {
        Invoke-WebRequest -Uri $rawUrl -Headers $headers -OutFile $destPath
        Write-Host " Done" -ForegroundColor Green
        $downloadCount++
    } catch {
        Write-Host " FAILED: $_" -ForegroundColor Red
    }
}

Write-Host "`nDownloaded $downloadCount file(s) to '$OutputFolder'." -ForegroundColor Cyan

# --- Convert using existing script ---
if ($downloadCount -gt 0) {
    Write-Host "`nStarting conversion to $Format..." -ForegroundColor Cyan
    $convertScript = Join-Path $PSScriptRoot "convert_vsd_to_pdf.ps1"
    & $convertScript -InputFolder $OutputFolder -OutputFolder $OutputFolder -Format $Format
}
