<#
.SYNOPSIS
    Offboard an AD user: disable, stamp, strip groups, quarantine.

.DESCRIPTION
    Standard leaver process: disables the account, records the date and the
    operator in the description (audit trail), removes every group membership
    except the primary group (Domain Users), and moves the object to the
    Disabled OU. The account is intentionally NOT deleted: deleting destroys
    the SID and the audit trail; quarantined accounts can be reviewed and
    purged later on a schedule.

.EXAMPLE
    .\Disable-OffboardedUser.ps1 -SamAccountName jsmith
#>
[CmdletBinding(SupportsShouldProcess)]
param(
    [Parameter(Mandatory)] [string]$SamAccountName,
    [string]$Domain = 'corp.lab'
)

Import-Module ActiveDirectory -ErrorAction Stop

$domainDN   = ($Domain.Split('.') | ForEach-Object { "DC=$_" }) -join ','
$disabledOU = "OU=Disabled,$domainDN"

$user = Get-ADUser $SamAccountName -Properties MemberOf, Description
if (-not $user) { throw "User $SamAccountName not found." }

if ($PSCmdlet.ShouldProcess($SamAccountName, 'Offboard')) {
    Disable-ADAccount $user
    Set-ADUser $user -Description ("Offboarded {0:yyyy-MM-dd} by {1}. Was: {2}" -f `
        (Get-Date), $env:USERNAME, $user.Description)

    foreach ($groupDN in $user.MemberOf) {
        Remove-ADGroupMember -Identity $groupDN -Members $user -Confirm:$false
        Write-Host "REMOVED from $((Get-ADGroup $groupDN).Name)"
    }

    Move-ADObject -Identity $user.DistinguishedName -TargetPath $disabledOU
    Write-Host "DONE: $SamAccountName disabled, stripped, moved to $disabledOU"
}
