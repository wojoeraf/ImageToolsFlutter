# PowerShell script to check DLL dependencies
param(
    [string]$DllPath = "jpeg_decoder_wrapper.dll"
)

Write-Host "Checking dependencies for: $DllPath" -ForegroundColor Green

if (-not (Test-Path $DllPath)) {
    Write-Host "Error: DLL file not found: $DllPath" -ForegroundColor Red
    exit 1
}

# Check if dumpbin is available (part of Visual Studio)
$dumpbin = Get-Command dumpbin -ErrorAction SilentlyContinue
if ($dumpbin) {
    Write-Host "`nUsing dumpbin to check dependencies:" -ForegroundColor Yellow
    & dumpbin /dependents $DllPath
} else {
    Write-Host "dumpbin not found. Install Visual Studio Build Tools for detailed dependency analysis." -ForegroundColor Yellow
}

# Check if turbojpeg.dll exists in the same directory
$turboJpegPath = Join-Path (Split-Path $DllPath -Parent) "turbojpeg.dll"
if (Test-Path $turboJpegPath) {
    Write-Host "`n✓ turbojpeg.dll found in the same directory" -ForegroundColor Green
} else {
    Write-Host "`n✗ turbojpeg.dll NOT found in the same directory" -ForegroundColor Red
    Write-Host "Expected location: $turboJpegPath" -ForegroundColor Yellow
}

# List all DLLs in the directory
$dllDir = Split-Path $DllPath -Parent
if (-not $dllDir) { $dllDir = "." }
Write-Host "`nDLLs in directory ($dllDir):" -ForegroundColor Yellow
Get-ChildItem -Path $dllDir -Filter "*.dll" | ForEach-Object {
    Write-Host "  - $($_.Name)" -ForegroundColor Cyan
}