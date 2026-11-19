function Test-MtNsmCaMfaAllUsers {
    <#
    .SYNOPSIS
    Checks that Conditional Access requires MFA for all users and all apps.

    .DESCRIPTION
    Høy grad: an enabled policy covers all users and all apps with MFA or an authentication strength, and excludes
    no more than the emergency access accounts and two other users or groups. Moderat grad: the policy has wider
    exclusions or is in report-only mode. Liten grad: none.
    #>
    [MaesterTest(
        Id = 'MP.NSM.1005',
        Title = 'Conditional Access krever MFA for alle brukere og alle apper',
        Product = 'entra',
        Feature = 'conditional-access',
        Area = 'authentication',
        ResourceType = 'ConditionalAccessPolicy',
        Severity = 'High',
        UserImpact = 'Medium',
        ImplementationCost = 'Low',
        Control = ('nsm-gp-ikt:2.6.7'),
        Mitre = ('T1078.004', 'T1110'),
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
    $rows = foreach ($p in Get-MtConditionalAccessPolicy) {
        $grant = $p.grantControls
        if (-not ((@($grant.builtInControls) -contains 'mfa') -or $grant.authenticationStrength.id)) { continue }
        $scope = Get-MtNsmCaScope -Policy $p -Excluded $excluded
        if (-not ($scope.AllUsers -and $scope.AllApps)) { continue }
        $limits = @($scope.Narrowing) + @(if (-not (Test-MtNsmCaRequiresMfa -Policy $p)) { 'kan oppfylles uten MFA' })
        [pscustomobject]@{
            Policy        = $p.displayName
            State         = $p.state
            Unntak        = $scope.Exceptions
            Begrensninger = $limits -join ', '
            Full          = $scope.Exceptions -le 2 -and $limits.Count -eq 0
        }
    }
    $rows = @($rows)
    $enabled = @($rows | Where-Object State -EQ 'enabled')

    if ($enabled | Where-Object Full) {
        $level = 'H'; $summary = 'En aktivert policy krever MFA for alle brukere og alle apper, med høyst to unntak og uten vilkår som begrenser den.'
    } elseif ($rows) {
        $level = 'M'; $summary = 'Policyen for alle brukere har mange unntak, begrensende vilkår, kan oppfylles uten MFA, eller står i report-only.'
    } else {
        $level = 'L'; $summary = 'Ingen policy ber om MFA for alle brukere og alle apper.'
    }
    Complete-MtNsmResult -Scope $nsmScope -Level $level -Summary $summary -Details (ConvertTo-MtNsmTable -InputObject $rows -Property Policy, State, Unntak, Begrensninger)
}
