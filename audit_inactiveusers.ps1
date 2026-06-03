# No special AuditLog permission needed for this one
$5DaysAgo = (Get-Date).AddDays(-5)

# We use CreatedDateTime instead of SignInActivity
$Users = Get-MgUser -All -Property "DisplayName", "UserPrincipalName", "Id", "AccountEnabled", "CreatedDateTime"

$OldAccounts = $Users | Where-Object {
    $_.CreatedDateTime -lt $5DaysAgo -and $_.AccountEnabled -eq $true
}

$ReportPath = Join-Path $PSScriptRoot "inactiveusers.csv"

$Results = foreach ($User in $OldAccounts) {
    [PSCustomObject]@{
        Name          = $User.DisplayName
        UPN           = $User.UserPrincipalName
        CreatedDate   = $User.CreatedDateTime
        Status        = "Flagged for Review"
    }
}

# Save to CSV and display a summary
$Results | Export-Csv -Path $ReportPath -NoTypeInformation
Write-Host "Audit Complete. Report saved to: $ReportPath" -ForegroundColor Green
Write-Host "Total flagged accounts: $($Results.Count)" -ForegroundColor White
