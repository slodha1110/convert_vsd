param(
    [string]$CertSubjectContains = 'Zscaler Root CA',
    [switch]$SkipAmpUsageCheck
)

$ErrorActionPreference = 'Stop'

function Convert-CertToPem {
    param(
        [System.Security.Cryptography.X509Certificates.X509Certificate2]$Cert
    )

    $base64 = [System.Convert]::ToBase64String(
        $Cert.RawData,
        [System.Base64FormattingOptions]::InsertLineBreaks
    )

    return "-----BEGIN CERTIFICATE-----`r`n$base64`r`n-----END CERTIFICATE-----`r`n"
}

$certs = @()
$certs += Get-ChildItem Cert:\CurrentUser\Root -ErrorAction SilentlyContinue |
    Where-Object { $_.Subject -like "*$CertSubjectContains*" -or $_.Issuer -like "*$CertSubjectContains*" }
$certs += Get-ChildItem Cert:\LocalMachine\Root -ErrorAction SilentlyContinue |
    Where-Object { $_.Subject -like "*$CertSubjectContains*" -or $_.Issuer -like "*$CertSubjectContains*" }

if ($null -eq $certs -or $certs.Count -eq 0) {
    throw "No certificate matching '$CertSubjectContains' was found in Windows Root stores."
}

$cert = $certs | Sort-Object NotAfter -Descending | Select-Object -First 1

Write-Host "Using certificate:" $cert.Subject
Write-Host "Thumbprint:" $cert.Thumbprint

$targetDirs = @(
    (Join-Path $HOME '.amp\certs'),
    (Join-Path $HOME '.config\amp\certs')
)

$pem = Convert-CertToPem -Cert $cert
$pemPaths = @()

foreach ($dir in $targetDirs) {
    New-Item -Path $dir -ItemType Directory -Force | Out-Null
    $pemPath = Join-Path $dir 'zscaler-root-ca.pem'
    Set-Content -Path $pemPath -Value $pem -Encoding ascii
    $pemPaths += $pemPath
    Write-Host "Wrote:" $pemPath
}

$primaryPemPath = $pemPaths[0]

[Environment]::SetEnvironmentVariable('NODE_EXTRA_CA_CERTS', $primaryPemPath, 'User')
$env:NODE_EXTRA_CA_CERTS = $primaryPemPath
Write-Host "Set user NODE_EXTRA_CA_CERTS=$primaryPemPath"

$wrapperPath = Join-Path $HOME '.local\bin\amp.bat'
New-Item -Path (Split-Path $wrapperPath -Parent) -ItemType Directory -Force | Out-Null

$wrapperContent = @'
@echo off
setlocal

set "AMP_CERT_PRIMARY=%USERPROFILE%\.amp\certs\zscaler-root-ca.pem"
set "AMP_CERT_SECONDARY=%USERPROFILE%\.config\amp\certs\zscaler-root-ca.pem"
set "AMP_CERT_FILE="

if defined NODE_EXTRA_CA_CERTS (
    if exist "%NODE_EXTRA_CA_CERTS%" (
        set "AMP_CERT_FILE=%NODE_EXTRA_CA_CERTS%"
    )
)

if not defined AMP_CERT_FILE (
    if exist "%AMP_CERT_PRIMARY%" (
        set "AMP_CERT_FILE=%AMP_CERT_PRIMARY%"
    ) else (
        if exist "%AMP_CERT_SECONDARY%" (
            set "AMP_CERT_FILE=%AMP_CERT_SECONDARY%"
        )
    )
)

if not defined AMP_CERT_FILE (
    powershell -NoProfile -ExecutionPolicy Bypass -Command "$ErrorActionPreference='Stop'; $stores=@('Cert:\CurrentUser\Root','Cert:\LocalMachine\Root'); $certs=@(); foreach($s in $stores){ $certs += Get-ChildItem $s -ErrorAction SilentlyContinue | Where-Object { $_.Subject -like '*Zscaler Root CA*' -or $_.Issuer -like '*Zscaler Root CA*' } }; if($certs.Count -gt 0){ $cert=$certs | Sort-Object NotAfter -Descending | Select-Object -First 1; $dir=Join-Path $env:USERPROFILE '.amp\certs'; New-Item -Path $dir -ItemType Directory -Force | Out-Null; $pemPath=Join-Path $dir 'zscaler-root-ca.pem'; $nl=[Environment]::NewLine; $pem='-----BEGIN CERTIFICATE-----'+$nl+[Convert]::ToBase64String($cert.RawData,[System.Base64FormattingOptions]::InsertLineBreaks)+$nl+'-----END CERTIFICATE-----'+$nl; Set-Content -Path $pemPath -Value $pem -Encoding ascii }" >nul 2>nul

    if exist "%AMP_CERT_PRIMARY%" (
        set "AMP_CERT_FILE=%AMP_CERT_PRIMARY%"
    ) else (
        if exist "%AMP_CERT_SECONDARY%" (
            set "AMP_CERT_FILE=%AMP_CERT_SECONDARY%"
        )
    )
)

if defined AMP_CERT_FILE (
    set "NODE_EXTRA_CA_CERTS=%AMP_CERT_FILE%"
    set "SSL_CERT_FILE=%AMP_CERT_FILE%"
)

if defined AMP_HOME (
    call "%AMP_HOME%\bin\amp.bat" %*
) else (
    call "%USERPROFILE%\.amp\bin\amp.bat" %*
)

set "AMP_EXITCODE=%ERRORLEVEL%"
endlocal & exit /b %AMP_EXITCODE%
'@

Set-Content -Path $wrapperPath -Value $wrapperContent -Encoding ascii
Write-Host "Updated wrapper:" $wrapperPath

$ampCommand = Get-Command amp -ErrorAction SilentlyContinue
if ($null -ne $ampCommand) {
    Write-Host "amp resolves to:" $ampCommand.Source
}

if (-not $SkipAmpUsageCheck) {
    Write-Host "Running: amp usage"
    & amp usage
    if ($LASTEXITCODE -ne 0) {
        Write-Host "amp usage exited with code" $LASTEXITCODE
    }
}
