function Test-MtNsmAdminPhishingResistantMethod {
    <#
    .SYNOPSIS
    Checks the share of administrators who have registered a phishing-resistant method.

    .DESCRIPTION
    Reads the authentication method registration report. Counts administrators with FIDO2, a passkey or Windows
    Hello for Business. Emergency access accounts from the Maester config and directory sync accounts are left out.
    Høy grad: all. Moderat grad: at least 60 %. Liten grad: fewer.
    #>
    [MaesterTest(
        Id = 'MP.NSM.1002',
        Title = 'Alle administratorer har registrert en phishing-resistent metode',
        Product = 'entra',
        Feature = 'authentication-methods',
        Area = 'privileged-access',
        ResourceType = 'User',
        Severity = 'High',
        UserImpact = 'Medium',
        ImplementationCost = 'Low',
        Control = ('nsm-varsel-2026:V1'),
        Mitre = ('T1078.004', 'T1566.002'),
        Service = 'Graph',
        License = 'AAD_PREMIUM',
        Permission = ('Graph:Scope:AuditLog.Read.All', 'Graph:Scope:Policy.Read.All'),
        Tag = ('NSM', 'NSM-Identitet'),
        Author = 'alventech'
    )]
    [CmdletBinding()]
    [OutputType([bool])]
    param()

    $nsmScope = 'Kontoer med katalogroller i Entra ID'

    $excluded = Get-MtNsmEmergencyAccess
    try {
        $details = @(Invoke-MtGraphRequest -RelativeUri 'reports/authenticationMethods/userRegistrationDetails' -Filter 'isAdmin eq true' -Select 'id,userPrincipalName,methodsRegistered' -ApiVersion v1.0)
        $policy = Invoke-MtGraphRequest -RelativeUri 'policies/authenticationMethodsPolicy' -ApiVersion v1.0
    } catch {
        if (Test-MtNsmAccessDenied $_) { Add-MtTestResultDetail -SkippedBecause NotAuthorized; return $null }
        throw
    }
    $admins = @($details | Where-Object {
        $_.id -notin $excluded -and $_.userPrincipalName -notin $excluded -and
        $_.userPrincipalName -notmatch '^(Sync_|ADToAADSyncServiceAccount@)'
    })
    if ($admins.Count -eq 0) {
        Add-MtTestResultDetail -SkippedBecause Custom -SkippedCustomReason 'Fant ingen administratorer i registreringsrapporten.'
        return $null
    }

    $rows = foreach ($a in $admins) {
        [pscustomobject]@{
            Bruker    = $a.userPrincipalName
            'Phishing-resistent' = if (Test-MtNsmPhishingResistantMethod $a.methodsRegistered) { 'Ja' } else { 'Nei' }
            Metoder   = (@($a.methodsRegistered) -join ', ')
        }
    }
    $share = @($rows | Where-Object 'Phishing-resistent' -EQ 'Ja').Count / $admins.Count
    $level = Get-MtNsmShareLevel -Share $share -High 1 -Moderate 0.6
    $summary = "$(Format-MtNsmPercent $share) av $(Format-MtNsmCount $admins.Count administrator administratorer) har en phishing-resistent metode."
    if (-not $excluded) { $summary += ' Ingen nødtilgangskontoer er satt i EmergencyAccessAccounts, så alle administratorer telles.' }
    if (@($policy.authenticationMethodConfigurations | Where-Object { $_.id -eq 'X509Certificate' -and $_.state -eq 'enabled' }).Count) {
        $summary += ' Certificate-based authentication (CBA) er på, men vises ikke i registreringsrapporten: administratorer som bruker den, telles som uten.'
    }
    Complete-MtNsmResult -Scope $nsmScope -Level $level -Summary $summary -Details (ConvertTo-MtNsmTable -InputObject @($rows | Sort-Object 'Phishing-resistent', Bruker) -Property Bruker, 'Phishing-resistent', Metoder)
}
