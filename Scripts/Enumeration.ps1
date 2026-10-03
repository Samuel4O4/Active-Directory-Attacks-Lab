# ===============================
# Active Directory LDAP Enumeration
# Author: Samuel4O4
# ===============================

Clear-Host

Write-Host "==============================================" -ForegroundColor Cyan
Write-Host "      ACTIVE DIRECTORY LDAP ENUMERATION"
Write-Host "==============================================" -ForegroundColor Cyan

# Get current domain information
$Domain = [System.DirectoryServices.ActiveDirectory.Domain]::GetCurrentDomain()
$PDC    = $Domain.PdcRoleOwner.Name
$DN     = ([ADSI]"").distinguishedName
$LDAP   = "LDAP://$PDC/$DN"

$Entry = New-Object System.DirectoryServices.DirectoryEntry($LDAP)
$Searcher = New-Object System.DirectoryServices.DirectorySearcher($Entry)

# --------------------------------------------------
Write-Host "`n========== DOMAIN INFORMATION ==========" -ForegroundColor Yellow

Write-Host ("Domain Name           : {0}" -f $Domain.Name)
Write-Host ("Forest                : {0}" -f $Domain.Forest.Name)
Write-Host ("Primary DC            : {0}" -f $PDC)
Write-Host ("Distinguished Name    : {0}" -f $DN)

# --------------------------------------------------
Write-Host "`n========== DOMAIN CONTROLLERS ==========" -ForegroundColor Yellow

foreach($dc in $Domain.DomainControllers)
{
    Write-Host $dc.Name
}

# --------------------------------------------------
Write-Host "`n========== DOMAIN USERS ==========" -ForegroundColor Yellow

$Searcher.Filter = "(&(objectCategory=person)(objectClass=user))"
$Searcher.PageSize = 1000

$Users = $Searcher.FindAll()

foreach($User in $Users)
{
    $Name = $User.Properties.samaccountname

    if($Name)
    {
        Write-Host $Name
    }
}

Write-Host "`nTotal Users : $($Users.Count)"

# --------------------------------------------------
Write-Host "`n========== DOMAIN ADMINS ==========" -ForegroundColor Yellow

$Searcher.Filter = "(&(objectCategory=group)(cn=Domain Admins))"

$Group = $Searcher.FindOne()

$Members = $Group.Properties.member

foreach($Member in $Members)
{
    $obj = [ADSI]"LDAP://$Member"

    Write-Host $obj.sAMAccountName
}

# --------------------------------------------------
Write-Host "`n========== DOMAIN GROUPS ==========" -ForegroundColor Yellow

$Searcher.Filter = "(objectClass=group)"

$Groups = $Searcher.FindAll()

foreach($Group in $Groups)
{
    Write-Host $Group.Properties.cn
}

Write-Host "`nTotal Groups : $($Groups.Count)"

# --------------------------------------------------
Write-Host "`n========== ENABLED USERS ==========" -ForegroundColor Yellow

$Searcher.Filter = "(&(objectCategory=person)(objectClass=user))"

foreach($Result in $Searcher.FindAll())
{
    $User = [ADSI]$Result.Path

    $Disabled = ($User.userAccountControl.Value -band 2)

    if(!$Disabled)
    {
        Write-Host $User.sAMAccountName
    }
}

# --------------------------------------------------
Write-Host "`n========== USERS WITH DESCRIPTION ==========" -ForegroundColor Yellow

$Searcher.Filter="(&(objectCategory=person)(objectClass=user)(description=*))"

foreach($Result in $Searcher.FindAll())
{
    $User = [ADSI]$Result.Path

    Write-Host ("{0,-20} {1}" -f $User.sAMAccountName,$User.description)
}

# --------------------------------------------------
Write-Host "`n========== SERVICE ACCOUNTS (SPNs) ==========" -ForegroundColor Yellow

$Searcher.Filter="(servicePrincipalName=*)"

foreach($Result in $Searcher.FindAll())
{
    $User=[ADSI]$Result.Path

    Write-Host ""
    Write-Host $User.sAMAccountName -ForegroundColor Cyan

    foreach($SPN in $User.servicePrincipalName)
    {
        Write-Host ("    {0}" -f $SPN)
    }
}

# --------------------------------------------------
# NEW SECTION: AS-REP Roastable Users (Preauth Disabled)
# --------------------------------------------------
Write-Host "`n========== AS-REP ROASTABLE USERS (PREAUTH DISABLED) ==========" -ForegroundColor Yellow

$Searcher.Filter = "(&(objectCategory=person)(objectClass=user))"
$Searcher.PageSize = 1000

$PreauthUsers = @()

foreach($Result in $Searcher.FindAll())
{
    $User = [ADSI]$Result.Path

    # Skip disabled accounts
    $Disabled = ($User.userAccountControl.Value -band 2)
    if($Disabled) { continue }

    # Check for DONT_REQ_PREAUTH flag (4194304 / 0x400000)
    $DontReqPreauth = ($User.userAccountControl.Value -band 4194304)

    if($DontReqPreauth)
    {
        $PreauthUsers += $User.sAMAccountName
        Write-Host $User.sAMAccountName -ForegroundColor White
    }
}

if($PreauthUsers.Count -eq 0)
{
    Write-Host "No users found with preauthentication disabled." -ForegroundColor Green
}
else
{
    Write-Host "`nTotal AS-REP Roastable Users : $($PreauthUsers.Count)" -ForegroundColor White
    Write-Host "These accounts can be targeted with AS-REP Roasting." -ForegroundColor White
}

# --------------------------------------------------
Write-Host "`n========== COMPUTERS ==========" -ForegroundColor Yellow

$Searcher.Filter="(objectClass=computer)"

foreach($Computer in $Searcher.FindAll())
{
    Write-Host $Computer.Properties.name
}

# --------------------------------------------------
Write-Host "`n========== ORGANIZATIONAL UNITS ==========" -ForegroundColor Yellow

$Searcher.Filter="(objectClass=organizationalUnit)"

foreach($OU in $Searcher.FindAll())
{
    Write-Host $OU.Properties.name
}

Write-Host "`n==============================================" -ForegroundColor Green
Write-Host "Enumeration Completed Successfully"
Write-Host "==============================================" -ForegroundColor Green
