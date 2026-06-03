# Find users missing a Job Title or Department (common in messy AD environments).
$IncompleteUsers = Get-MgUser -All -Property "DisplayName,JobTitle,Department,UserPrincipalName" | Where-Object { -not $_.JobTitle -or -not $_.Department }

# Correctly join the local script directory path with the file name.
$ReportPath = Join-Path $PSScriptRoot "incomplete_accounts.csv"

# Export to a CSV.
$IncompleteUsers | Select-Object DisplayName, UserPrincipalName | Export-Csv -Path $ReportPath -NoTypeInformation
