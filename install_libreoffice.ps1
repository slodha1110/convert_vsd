

$ErrorActionPreference = "Stop"

$candidates = @(
    "C:\Program Files\LibreOffice\program\soffice.exe",
    "C:\Program Files (x86)\LibreOffice\program\soffice.exe"
)
foreach ($path in $candidates) {
    if (Test-Path $path) {
        Write-Host "LibreOffice is already installed at: $path" -ForegroundColor Green
        exit
    }
}

$installerDir = Join-Path $env:TEMP "libreoffice_installer"
if (-not (Test-Path $installerDir)) {
    New-Item -ItemType Directory -Path $installerDir -Force | Out-Null
}
$msiPath = Join-Path $installerDir "LibreOffice.msi"
$downloadUrl = "https://download.documentfoundation.org/libreoffice/stable/26.2.1/win/x86_64/LibreOffice_26.2.1_Win_x86-64.msi"

if (-not (Test-Path $msiPath)) {
    Write-Host "Downloading LibreOffice... (this may take a few minutes)" -ForegroundColor Cyan
    [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
    $ProgressPreference = 'SilentlyContinue'
    Invoke-WebRequest -Uri $downloadUrl -OutFile $msiPath -UseBasicParsing
    Write-Host "Download complete." -ForegroundColor Green
}

Write-Host "Installing LibreOffice silently..." -ForegroundColor Cyan
$installArgs = "/i `"$msiPath`" /qn /norestart ADDLOCAL=ALL REGISTER_ALL_MSO_TYPES=0 REGISTER_NO_MSO_TYPES=1 ISCHECKFORPRODUCTUPDATES=0 CREATEDESKTOPLINK=0"
$process = Start-Process -FilePath "msiexec.exe" -ArgumentList $installArgs -Wait -PassThru
if ($process.ExitCode -ne 0) {
    Write-Host "Installation failed (exit code $($process.ExitCode)). Make sure you are running as Administrator." -ForegroundColor Red
    exit 1
}
Write-Host "LibreOffice installed successfully!" -ForegroundColor Green
