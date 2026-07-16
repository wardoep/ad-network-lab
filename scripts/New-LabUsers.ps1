<#
.SYNOPSIS
    Bulk-provision Active Directory users from a CSV (First,Last,Department).

.DESCRIPTION
    For each row: derives the username (first initial + last name, lowercase),
    creates the account in OU=<Department>,OU=Departments, adds it to the
    GG-<Department> group, and forces a password change at first logon.
    Rows whose account already exists are skipped, so the script is safe
    to re-run. Duplicate-derived usernames get a numeric suffix and a warning.

.EXAMPLE
    .\New-LabUsers.ps1 -CsvPath .\users.sample.csv
#>
[CmdletBinding()]
param(
    [Parameter(Mandatory)] [string]$CsvPath,
    [string]$Domain          = 'corp.lab',
    [string]$DefaultPassword = 'Welcome-2-corp!'   # must satisfy domain policy; changed at first logon
)

Import-Module ActiveDirectory -ErrorAction Stop

$domainDN = ($Domain.Split('.') | ForEach-Object { "DC=$_" }) -join ','
$created = 0; $skipped = 0

foreach ($row in Import-Csv $CsvPath) {
    if (-not ($row.First -and $row.Last -and $row.Department)) {
        Write-Warning "Skipping incomplete row: $($row | ConvertTo-Json -Compress)"
        continue
    }

    $sam  = ('{0}{1}' -f $row.First.Substring(0,1), $row.Last).ToLower() -replace '[^a-z0-9]', ''
    $base = $sam; $i = 1
    while ((Get-ADUser -Filter "SamAccountName -eq '$sam'") -and
           -not (Get-ADUser -Filter "SamAccountName -eq '$sam'" |
                 Where-Object { $_.GivenName -eq $row.First -and $_.Surname -eq $row.Last })) {
        $i++; $sam = "$base$i"
        Write-Warning "Username collision for $($row.First) $($row.Last); trying $sam"
    }

    if (Get-ADUser -Filter "SamAccountName -eq '$sam'") {
        Write-Host "SKIP   $sam already exists"
        $skipped++
        continue
    }

    $ou = "OU=$($row.Department),OU=Departments,$domainDN"
    New-ADUser -Name "$($row.First) $($row.Last)" `
        -GivenName $row.First -Surname $row.Last `
        -SamAccountName $sam -UserPrincipalName "$sam@$Domain" `
        -Path $ou `
        -AccountPassword (ConvertTo-SecureString $DefaultPassword -AsPlainText -Force) `
        -ChangePasswordAtLogon $true -Enabled $true

    Add-ADGroupMember -Identity "GG-$($row.Department)" -Members $sam
    Write-Host "CREATE $sam -> $ou (+GG-$($row.Department))"
    $created++
}

Write-Host "`nDone: $created created, $skipped skipped."
