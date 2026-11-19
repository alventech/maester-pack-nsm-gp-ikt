function Test-MtNsmLegacyAuthBlocked {
    <#
    .SYNOPSIS
    Checks that Conditional Access blocks legacy authentication for all users.

    .DESCRIPTION
    Høy grad: an enabled policy blocks Exchange ActiveSync and other legacy clients for all users. Moderat grad:
    such a policy is in report-only mode or covers only some users. Liten grad: none.
    #>
    [MaesterTest(
        Id = 'MP.NSM.2001',
        Title = 'Legacy authentication er blokkert',
        Product = 'entra',
        Feature = 'conditional-access',
        Area = 'authentication',
        ResourceType = 'ConditionalAccessPolicy',
        Severity = 'High',
        UserImpact = 'Low',
        ImplementationCost = 'Low',
        Control = ('nsm-gp-ikt:2.3.3', 'nsm-gp-ikt:2.6.7'),
        Mitre = ('T1078.004', 'T1110'),
        Service = 'Graph',
        License = 'AAD_PREMIUM',
        Permission = 'Graph:Scope:Policy.Read.All',
        Tag = ('NSM', 'NSM-M365'),
        Author = 'alventech'
    )]
    [CmdletBinding()]
    [OutputType([bool])]
    param()

    $nsmScope = 'Entra ID-kontoer, pålogging til skyapper'

    $excluded = Get-MtNsmEmergencyAccess
    $rows = foreach ($p in Get-MtConditionalAccessPolicy) {
        $clients = @($p.conditions.clientAppTypes)
        if (@($p.grantControls.builtInControls) -notcontains 'block' -or $clients -notcontains 'exchangeActiveSync' -or $clients -notcontains 'other') { continue }
        $scope = Get-MtNsmCaScope -Policy $p -Excluded $excluded
        # A legacy authentication block is narrowed to client app types by design.
        $limits = @($scope.Narrowing | Where-Object { $_ -ne 'client apps' })
        [pscustomobject]@{
            Policy        = $p.displayName
            State         = $p.state
            Brukere       = if ($scope.AllUsers) { 'Alle' } else { 'Utvalgte' }
            Unntak        = $scope.Exceptions
            Begrensninger = $limits -join ', '
            Full          = $scope.AllUsers -and $scope.AllApps -and $scope.Exceptions -le 2 -and $limits.Count -eq 0
        }
    }
    $rows = @($rows)
    $defaults = [bool](Invoke-MtGraphRequest -RelativeUri 'policies/identitySecurityDefaultsEnforcementPolicy' -ApiVersion v1.0).isEnabled

    if ($rows | Where-Object { $_.State -eq 'enabled' -and $_.Full }) {
        $level = 'H'; $summary = 'En aktivert policy blokkerer legacy authentication for alle brukere og apper, med høyst to unntak.'
    } elseif ($defaults) {
        $level = 'H'; $summary = 'Security defaults er på og blokkerer legacy authentication.'
    } elseif ($rows) {
        $level = 'M'; $summary = 'Blokkering av legacy authentication står i report-only, gjelder bare noen brukere eller apper, eller har mange unntak.'
    } else {
        $level = 'L'; $summary = 'Ingen policy blokkerer legacy authentication, og security defaults er av.'
    }
    Complete-MtNsmResult -Scope $nsmScope -Level $level -Summary $summary -Details (ConvertTo-MtNsmTable -InputObject $rows -Property Policy, State, Brukere, Unntak, Begrensninger)
}
