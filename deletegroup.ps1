# Delete the group.
Remove-MgGroup -GroupId "00000000-0000-0000-0000-000000000000"

# Verify the output.
Write-Output "Entra ID groups deleted."
