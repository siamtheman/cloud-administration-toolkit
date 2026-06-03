# Define the password, custom domain name, and group.
$PasswordProfile = @{ Password = "your_password"; ForceChangePasswordNextSignIn = $true }
$Domain = "your_domain_name"
$GroupName = "your_group_name"
$Department = "your_department_name"
$JobTitle = "your_job_title"
$CompanyName = "your_company_name"

# Create new user.
$newUser = New-MgUser -DisplayName "User Name" -PasswordProfile $PasswordProfile -AccountEnabled -MailNickname "user_name" -UserPrincipalName "user_name@$($Domain)" -Department $Department -JobTitle $JobTitle -CompanyName $CompanyName
Write-Host "Created User: $($newUser.DisplayName) with ID: $($newUser.Id)" -ForegroundColor Cyan

# Get the IT Group ID automatically
$targetGroup = Get-MgGroup -Filter "DisplayName eq '$($GroupName)'"

# Add the new user to the group
if ($targetGroup) {
   New-MgGroupMember -GroupId $targetGroup.Id -DirectoryObjectId $newUser.Id
   Write-Host "Success: Added $($newUser.DisplayName) to $($GroupName) group." -ForegroundColor Green
} 
else {
   Write-Host "Error: Group '$($GroupName)' not found." -ForegroundColor Red
}
