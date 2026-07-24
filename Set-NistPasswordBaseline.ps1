[CmdletBinding()]
param(
    [int]$MinPasswordLength = 12,
    [int]$MinPasswordAge = 1,
    [int]$PasswordHistorySize = 5,
    [int]$LockoutThreshold = 5,
    [int]$LockoutDurationMinutes = 10,
    [int]$LockoutWindowMinutes = 10
)

function Assert-Admin {
    $currentUser = [Security.Principal.WindowsPrincipal]::new([Security.Principal.WindowsIdentity]::GetCurrent())
    if (-not $currentUser.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
        Write-Error "This script must be run as Administrator. Re-launch PowerShell with 'Run as administrator' and try again."
        exit 1
    }
}

Assert-Admin

Write-Host "Current policy (before)" -ForegroundColor Cyan
net accounts

Write-Host "Applying NIST-aligned baseline..." -ForegroundColor Cyan

# Note: /maxpwage:UNLIMITED disables forced password expiration, per NIST guidance against periodic rotation absent evidence of compromise.
net accounts `
    /minpwlen:$MinPasswordLength `
    /minpwage:$MinPasswordAge `
    /maxpwage:UNLIMITED `
    /uniquepw:$PasswordHistorySize `
    /lockoutthreshold:$LockoutThreshold `
    /lockoutduration:$LockoutDurationMinutes `
    /lockoutwindow:$LockoutWindowMinutes

if ($LASTEXITCODE -ne 0) {
    Write-Error "One or more settings failed to apply. Review output above."
    exit 1
}

Write-Host "Updated policy (after)" -ForegroundColor Green
net accounts

Write-Host "Note: password complexity requirements were left DISABLED intentionally," -ForegroundColor Yellow
Write-Host "per NIST 800-63B guidance against mandatory composition rules." -ForegroundColor Yellow
Write-Host "Breached-password screening is NOT configured. Requires Entra ID Password" -ForegroundColor Yellow
Write-Host "Protection (P1) or a third-party tool; documented as a known gap." -ForegroundColor Yellow
