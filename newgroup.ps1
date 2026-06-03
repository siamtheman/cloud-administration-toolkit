# Define the group parameters
$GroupProfile = @{ DisplayName = "Operations"; Description = "Test group."; MailEnabled = $false; SecurityEnabled = $true; MailNickname = "Operations" }

# Create the group
$newGroup = New-MgGroup @GroupProfile

# Verify the output
$newGroup | Select-Object Id, DisplayName, Description
