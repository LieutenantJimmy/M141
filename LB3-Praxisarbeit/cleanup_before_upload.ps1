# =============================================================================
# cleanup_before_upload.ps1
# Removes OS/Office junk so it never reaches GitLab.
# Run this once from PowerShell before drag-dropping into the Web IDE.
#
# Usage:
#   cd C:\Users\Giovanni\Documents\GitHub\M141\LB3-Praxisarbeit
#   powershell -ExecutionPolicy Bypass -File .\cleanup_before_upload.ps1
# =============================================================================

$ErrorActionPreference = "Continue"
$root = $PSScriptRoot

Write-Host "Cleaning $root ..." -ForegroundColor Cyan

# Close Excel first, otherwise the .~lock file stays
Get-Process EXCEL  -ErrorAction SilentlyContinue | ForEach-Object { Write-Host "  (please close Excel manually)" -ForegroundColor Yellow }
Get-Process soffice -ErrorAction SilentlyContinue | ForEach-Object { Write-Host "  (please close LibreOffice manually)" -ForegroundColor Yellow }

$patterns = @(
    "csv\__MACOSX",
    "csv\backpacker_lb3.csv",
    "backpacker_lb3.csv.zip",
    ".~lock.*.xlsx#"
)

foreach ($p in $patterns) {
    $items = Get-ChildItem -Path $root -Recurse -Force -Filter $p -ErrorAction SilentlyContinue
    foreach ($i in $items) {
        Write-Host "  remove: $($i.FullName)"
        Remove-Item -Recurse -Force -ErrorAction SilentlyContinue $i.FullName
    }
}

# Recurse to kill any stray .DS_Store / Thumbs.db / ._files
Get-ChildItem -Path $root -Recurse -Force -Include ".DS_Store","Thumbs.db","._*" -ErrorAction SilentlyContinue | ForEach-Object {
    Write-Host "  remove: $($_.FullName)"
    Remove-Item -Force -ErrorAction SilentlyContinue $_.FullName
}

Write-Host "" -ForegroundColor Green
Write-Host "Done. The repo is now ready to drag-drop into GitLab Web IDE." -ForegroundColor Green
