# VSD to PDF Converter

Batch converts all `.vsd` (Microsoft Visio) files to PDF using LibreOffice.

## Prerequisites

- Windows 10/11 (x64)
- PowerShell 5.1+
- Internet connection (for first-time setup only)

## Setup

### Step 1 — Install LibreOffice (one-time, requires Administrator)

1. Open **PowerShell as Administrator**:
   - Press `Win` key → type `PowerShell`
   - Right-click → **Run as administrator**

2. Run the install script:
   ```powershell
   powershell -ExecutionPolicy Bypass -File "c:\Users\M066019\convert_vsd\install_libreoffice.ps1"
   ```

This downloads and silently installs LibreOffice (~355 MB). Only needs to be done **once**.

---

## Usage

### Step 2 — Convert VSD files to PDF (no admin needed)

Place your `.vsd` files in the `VSD_scripts` folder, then run:

```powershell
powershell -ExecutionPolicy Bypass -File "c:\Users\M066019\convert_vsd\convert_vsd_to_pdf.ps1"
```

PDFs will be saved in the same `VSD_scripts` folder.

### Custom Input/Output Folders

```powershell
powershell -ExecutionPolicy Bypass -File "c:\Users\M066019\convert_vsd\convert_vsd_to_pdf.ps1" -InputFolder "C:\path\to\vsd\files" -OutputFolder "C:\path\to\output"
```

---

## File Structure

```
convert_vsd/
├── install_libreoffice.ps1   # One-time setup (run as Admin)
├── convert_vsd_to_pdf.ps1    # Conversion script (run anytime)
├── VSD_scripts/              # Place .vsd files here
│   ├── example.vsd
│   └── example.pdf           # Output appears here
└── README.md
```

## AMP TLS Repair (if AMP shows connection/certificate errors)

If `amp` fails with certificate or connection errors in a corporate network, run:

```powershell
powershell -ExecutionPolicy Bypass -File "c:\Users\M066019\convert_vsd\fix_amp_tls.ps1"
```

This refreshes the trusted Zscaler certificate PEM and updates your AMP wrapper.

### Updated File Structure

```
convert_vsd/
├── install_libreoffice.ps1
├── convert_vsd_to_pdf.ps1
├── fix_amp_tls.ps1          # Re-applies AMP TLS trust/wrapper fix
├── VSD_scripts/
└── README.md
```

## Troubleshooting

| Issue | Solution |
|-------|----------|
| `Installation failed (exit code 1603)` | Run `install_libreoffice.ps1` as Administrator |
| `LibreOffice is not installed` | Run `install_libreoffice.ps1` first |
| `No .vsd files found` | Place `.vsd` files in the `VSD_scripts` folder |
| Download fails | Check internet/firewall; manually download from [libreoffice.org](https://www.libreoffice.org/download/) and place MSI at `%TEMP%\libreoffice_installer\LibreOffice.msi` |
