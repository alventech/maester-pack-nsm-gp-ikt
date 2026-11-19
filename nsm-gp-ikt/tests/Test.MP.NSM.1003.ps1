function Test-MtNsmUserPhishingResistantMethod {
    <#
    .SYNOPSIS
    Checks the share of member users who have registered a phishing-resistant method.

    .DESCRIPTION
    Høy grad: at least 95 %. Moderat grad: at least 50 %. Liten grad: fewer. Guests and directory sync accounts
    are left out.
    #>
    [MaesterTest(
        Id = 'MP.NSM.1003',
        Title = 'Brukerne har registrert en phishing-resistent metode',
        Product = 'entra',
        Feature = 'authentication-methods',
        Area = 'authentication',
        ResourceType = 'User',
        Severity = 'Medium',
        UserImpact = 'Medium',
        ImplementationCost = 'Medium',
        Control = ('nsm-varsel-2026:V1'),
        Mitre = 'T1566.002',
        Service = 'Graph',
        License = 'AAD_PREMIUM',
        Permission = ('Graph:Scope:AuditLog.Read.All', 'Graph:Scope:Directory.Read.All', 'Graph:Scope:Policy.Read.All'),
        Tag = ('NSM', 'NSM-Identitet'),
        Author = 'alventech'
    )]
    [CmdletBinding()]
    [OutputType([bool])]
    param()

    $nsmScope = 'Aktive, lisensierte medlemskontoer i Entra ID'

    try {
        $details = @(Invoke-MtGraphRequest -RelativeUri 'reports/authenticationMethods/userRegistrationDetails' -Filter "userType eq 'member'" -Select 'id,userPrincipalName,methodsRegistered' -ApiVersion v1.0)
        $active = @(Invoke-MtGraphRequest -RelativeUri 'users' -Filter "accountEnabled eq true and userType eq 'Member'" -Select 'id,assignedLicenses' -ApiVersion v1.0)
        $policy = Invoke-MtGraphRequest -RelativeUri 'policies/authenticationMethodsPolicy' -ApiVersion v1.0
    } catch {
        if (Test-MtNsmAccessDenied $_) { Add-MtTestResultDetail -SkippedBecause NotAuthorized; return $null }
        throw
    }
    # Count the people who sign in: enabled members with a licence. Shared, room and resource mailboxes are
    # usually unlicensed or disabled.
    $people = [System.Collections.Generic.HashSet[string]]::new([string[]]@($active | Where-Object { @($_.assignedLicenses).Count -gt 0 } | ForEach-Object { [string]$_.id }))
    $users = @($details | Where-Object { $people.Contains([string]$_.id) -and $_.userPrincipalName -notmatch '^(Sync_|ADToAADSyncServiceAccount@)' })
    if ($users.Count -eq 0) {
        Add-MtTestResultDetail -SkippedBecause Custom -SkippedCustomReason 'Fant ingen aktive brukere med lisens i registreringsrapporten.'
        return $null
    }

    $strong = @($users | Where-Object { Test-MtNsmPhishingResistantMethod $_.methodsRegistered })
    $share = $strong.Count / $users.Count
    $byMethod = $users.methodsRegistered | Group-Object | Sort-Object Count -Descending | ForEach-Object { [pscustomobject]@{ Metode = $_.Name; Brukere = $_.Count } }
    $summary = "$(Format-MtNsmPercent $share) av $(Format-MtNsmCount $users.Count 'aktiv bruker med lisens' 'aktive brukere med lisens') har en phishing-resistent metode."
    if (@($policy.authenticationMethodConfigurations | Where-Object { $_.id -eq 'X509Certificate' -and $_.state -eq 'enabled' }).Count) {
        $summary += ' Certificate-based authentication (CBA) er på, men vises ikke i registreringsrapporten: brukere som bruker den, telles som uten.'
    }
    Complete-MtNsmResult -Scope $nsmScope -Level (Get-MtNsmShareLevel -Share $share -High 0.95 -Moderate 0.5) -Summary $summary `
        -Details (ConvertTo-MtNsmTable -InputObject @($byMethod) -Property Metode, Brukere)
}
