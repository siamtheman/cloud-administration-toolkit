# Declare the parameters.
[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)]
    [string[]]$Departments,

    [string]$Suffix = "Group",

    [string]$DescriptionTemplate = "Security group for the {0} department (membership synced from user attributes)."
)

foreach ($dept in $Departments) {

    $displayName  = "$dept-$Suffix"
    $mailNickname = ($dept -replace '\s', '') + $Suffix
    $description  = $DescriptionTemplate -f $dept

    Write-Host "Processing department: $dept" -ForegroundColor Magenta

    # Find or create the group.
    $group = Get-MgGroup -Filter "displayName eq '$displayName'" -ErrorAction SilentlyContinue

    if (-not $group) {
        $groupParams = @{
            DisplayName     = $displayName
            MailNickname    = $mailNickname
            Description     = $description
            MailEnabled     = $false
            SecurityEnabled = $true
            GroupTypes      = @()   # empty = standard Assigned group, no license required
        }

        try {
            Write-Host "Creating group '$displayName'..." -ForegroundColor Cyan
            $group = New-MgGroup -BodyParameter $groupParams
            Write-Host "Group created (Id: $($group.Id))." -ForegroundColor Green
        }
        catch {
            Write-Error "Failed to create group '$displayName': $_"
            continue
        }
    }
    else {
        Write-Host "Group '$displayName' already exists (Id: $($group.Id)). Syncing membership..." -ForegroundColor Yellow
    }

    # Query users matching this department.
    $matchingUsers = Get-MgUser -Filter "department eq '$dept'" -All -ErrorAction SilentlyContinue

    if (-not $matchingUsers) {
        Write-Warning "No users found with department = '$dept'. Skipping membership sync."
        continue
    }

    # Get current members so we don't re-add duplicates
    $currentMemberIds = (Get-MgGroupMember -GroupId $group.Id -All | Select-Object -ExpandProperty Id)

    $added = 0
    foreach ($user in $matchingUsers) {
        if ($user.Id -notin $currentMemberIds) {
            try {
                New-MgGroupMember -GroupId $group.Id -DirectoryObjectId $user.Id
                $added++
            }
            catch {
                Write-Warning "Could not add $($user.DisplayName): $_"
            }
        }
    }

    Write-Host "Sync complete for '$displayName': $added new member(s) added, $($matchingUsers.Count) total matched." -ForegroundColor Green
}

Write-Host "All department groups processed." -ForegroundColor Green
