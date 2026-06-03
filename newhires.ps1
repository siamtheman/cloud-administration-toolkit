# Configuration.
$Domain = "your_domain_name"
$CSVPath = Join-Path $PSScriptRoot "newhires.csv"

# Import and process.
$NewUsers = Import-Csv -Path $CSVPath

# Combine CSV data with your logic.
foreach ($User in $NewUsers) {
    $UPN = "$($User.MailNickname)@$($Domain)"
    $UserData = @{
        DisplayName       = $User.DisplayName
        MailNickname      = $User.MailNickname
        UserPrincipalName = $UPN
        JobTitle          = $User.JobTitle
        Department        = $User.Department
        CompanyName       = $User.CompanyName
        AccountEnabled    = $true
        PasswordProfile   = @{ 
            Password = "your_password" 
            ForceChangePasswordNextSignIn = $true 
        }
    }

    try {
        Write-Host "Processing $($User.DisplayName)..." -ForegroundColor Gray
        $CreatedUser = New-MgUser @UserData
        Write-Host "Success: Created $($CreatedUser.UserPrincipalName)" -ForegroundColor Green
    }
    catch {
        Write-Host "Failed to create $($UPN): $($_.Exception.Message)" -ForegroundColor Red
    }
}
