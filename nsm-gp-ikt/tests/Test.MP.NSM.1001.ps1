function Test-MtNsmCaPhishingResistantMfa {
    <#
    .SYNOPSIS
    Checks that Conditional Access requires a phishing-resistant authentication strength for all users and all apps.

    .DESCRIPTION
    NSM's alert of 27.10.2026 asks for phishing-resistant multifactor authentication (V1), building on GP-IKT 2.6.7.
    Høy grad: an enabled policy requires a phishing-resistant strength for all users and all apps.
    Moderat grad: an enabled policy does so for administrator roles or some apps, or an all-users policy is in
    report-only mode. Liten grad: no policy requires a phishing-resistant strength.
    #>
    [MaesterTest(
        Id = 'MP.NSM.1001',
        Title = 'Conditional Access krever phishing-resistent MFA for alle brukere og apper',
        Product = 'entra',
        Feature = 'conditional-access',
        Area = 'authentication',
        ResourceType = 'ConditionalAccessPolicy',
        Severity = 'High',
        UserImpact = 'Medium',
        ImplementationCost = 'Medium',
        Control = ('nsm-varsel-2026:V1'),
        Mitre = 'T1566.002',
        Service = 'Graph',
        License = 'AAD_PREMIUM',
        Permission = 'Graph:Scope:Policy.Read.All',
        Tag = ('NSM', 'NSM-Identitet'),
        Author = 'alventech'
    )]
    [CmdletBinding()]
    [OutputType([bool])]
    param()

    $nsmScope = 'Entra ID-kontoer, pålogging til skyapper'

    $excluded = Get-MtNsmEmergencyAccess
    $strengths = Get-MtNsmPhishingResistantStrengthId
    $policies = @(Get-MtConditionalAccessPolicy | Where-Object { $_.grantControls.authenticationStrength.id -and $_.grantControls.authenticationStrength.id -in $strengths })

    $rows = foreach ($p in $policies) {
        $scope = Get-MtNsmCaScope -Policy $p -Excluded $excluded
        $enforced = Test-MtNsmCaRequiresMfa -Policy $p -StrengthId $strengths
        $limits = @($scope.Narrowing) + @(if (-not $enforced) { 'kan oppfylles med en annen kontroll' })
        [pscustomobject]@{
            Policy        = $p.displayName
            State         = $p.state
            Brukere       = if ($scope.AllUsers) { 'Alle' } elseif ($p.conditions.users.includeRoles) { "$(@($p.conditions.users.includeRoles).Count) roller" } else { 'Utvalgte' }
            Apper         = if ($scope.AllApps) { 'Alle' } else { 'Utvalgte' }
            Unntak        = $scope.Exceptions
            Begrensninger = $limits -join ', '
            Full          = $scope.AllUsers -and $scope.AllApps -and $scope.Exceptions -le 2 -and $limits.Count -eq 0
        }
    }
    $rows = @($rows)
    $enabled = @($rows | Where-Object State -EQ 'enabled')

    if ($enabled | Where-Object Full) {
        $level = 'H'; $summary = 'En aktivert policy krever phishing-resistent authentication strength for alle brukere og alle apper, med høyst to unntak og uten vilkår som begrenser den.'
    } elseif ($enabled -or ($rows | Where-Object Full)) {
        $level = 'M'; $summary = 'Phishing-resistent authentication strength kreves bare for noen brukere, apper eller situasjoner, med mange unntak, eller policyen for alle står i report-only.'
    } else {
        $level = 'L'; $summary = 'Ingen Conditional Access-policy krever phishing-resistent authentication strength.'
    }
    Complete-MtNsmResult -Scope $nsmScope -Level $level -Summary $summary -Details (ConvertTo-MtNsmTable -InputObject $rows -Property Policy, State, Brukere, Apper, Unntak, Begrensninger)
}
