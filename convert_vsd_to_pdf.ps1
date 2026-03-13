

# Convert all .vsd files to PDF and VSDX using LibreOffice (no admin needed)
# Usage: .\convert_vsd_to_pdf.ps1 [-InputFolder <path>] [-OutputFolder <path>] [-Format <pdf|vsdx|both>]

param(
    [string]$InputFolder = (Join-Path $PSScriptRoot "VSD_scripts"),
    [string]$OutputFolder = (Join-Path $PSScriptRoot "VSD_scripts"),
    [ValidateSet("pdf", "svg", "png")]
    [string]$Format = "pdf"
)

$ErrorActionPreference = "Stop"

$soffice = $null
$candidates = @(
    "C:\Program Files\LibreOffice\program\soffice.exe",
    "C:\Program Files (x86)\LibreOffice\program\soffice.exe"
)
foreach ($path in $candidates) {
    if (Test-Path $path) { $soffice = $path; break }
}

if (-not $soffice) {
    Write-Host "LibreOffice is not installed. Run install_libreoffice.ps1 as Administrator first." -ForegroundColor Red
    exit 1
}

$vsdFiles = Get-ChildItem -Path $InputFolder -Filter "*.vsd" -Recurse
if ($vsdFiles.Count -eq 0) {
    Write-Host "No .vsd files found in '$InputFolder'." -ForegroundColor Yellow
    exit
}

Write-Host "Found $($vsdFiles.Count) .vsd file(s). Converting..." -ForegroundColor Cyan

if (-not (Test-Path $OutputFolder)) {
    New-Item -ItemType Directory -Path $OutputFolder -Force | Out-Null
}

$successCount = 0
$failCount = 0

foreach ($file in $vsdFiles) {
        Write-Host "Converting: $($file.Name) -> $Format" -NoNewline
        try {
            $proc = Start-Process -FilePath $soffice -ArgumentList "--headless", "--convert-to", $Format, "--outdir", "`"$OutputFolder`"", "`"$($file.FullName)`"" -Wait -PassThru -NoNewWindow
            if ($proc.ExitCode -eq 0) {
                Write-Host " -> Done" -ForegroundColor Green
                $successCount++
            } else {
                Write-Host " -> FAILED (exit code $($proc.ExitCode))" -ForegroundColor Red
                $failCount++
            }
        } catch {
            Write-Host " -> FAILED: $_" -ForegroundColor Red
            $failCount++
        }
}

Write-Host "`nConversion complete: $successCount succeeded, $failCount failed." -ForegroundColor Cyan
