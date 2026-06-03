# Check the last 5 days.
$5DaysAgo = (Get-Date).AddDays(-5)

# Check for inactive users and generate a CSV.
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

# Save CSV and display a summary.
$Results | Export-Csv -Path $ReportPath -NoTypeInformation
Write-Host "Audit Complete. Report saved to: $ReportPath" -ForegroundColor Green
Write-Host "Total flagged accounts: $($Results.Count)" -ForegroundColor White
