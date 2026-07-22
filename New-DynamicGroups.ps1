# Declare the parameters.
[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)]
    [string[]]$Departments,

    [string]$Suffix = "Dynamic",

    [string]$DescriptionTemplate = "Dynamic security group for the {0} department."
)

foreach ($dept in $Departments) {

    $displayName    = "$dept-$Suffix"
    $mailNickname   = ($dept -replace '\s', '') + $Suffix
    $membershipRule = "(user.department -eq `"$dept`")"
    $description    = $DescriptionTemplate -f $dept

    Write-Host "`n=== Processing department: $dept ===" -ForegroundColor Magenta

    # Check for existing group with the same display name.
    $existing = Get-MgGroup -Filter "displayName eq '$displayName'" -ErrorAction SilentlyContinue
    if ($existing) {
        Write-Warning "A group named '$displayName' already exists (Id: $($existing.Id)). Skipping."
        continue
    }

    # Build the group object.
    $groupParams = @{
        DisplayName                   = $displayName
        MailNickname                  = $mailNickname
        Description                   = $description
        MailEnabled                   = $false
        SecurityEnabled               = $true
        GroupTypes                    = @("DynamicMembership")
        MembershipRule                = $membershipRule
        MembershipRuleProcessingState = "On"
    }

    # Create the group.
    try {
        Write-Host "Creating dynamic group '$displayName'..." -ForegroundColor Cyan
        $newGroup = New-MgGroup -BodyParameter $groupParams
        Write-Host "Group created successfully." -ForegroundColor Green
        Write-Host "Id:              $($newGroup.Id)"
        Write-Host "DisplayName:     $($newGroup.DisplayName)"
        Write-Host "MembershipRule:  $membershipRule"
    }
    catch {
        Write-Error "Failed to create group '$displayName': $_"
    }
}

Write-Host "All department groups processed." -ForegroundColor Green
Write-Host "Note: dynamic group membership evaluation can take a few minutes to populate." -ForegroundColor Yellow
