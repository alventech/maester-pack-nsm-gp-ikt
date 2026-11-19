function Test-MtNsmCaManagedDevice {
    <#
    .SYNOPSIS
    Checks that Conditional Access gives access based on both the user and the device.

    .DESCRIPTION
    Looks for Conditional Access policies that require a compliant or hybrid joined device, where the requirement
    cannot be met by another control ("MFA or compliant device" does not require a device).
    Høy grad: an enabled policy does so for all users and for all apps or Office 365, with at most two exceptions
    and no narrowing conditions. Moderat grad: for some users or apps, with many exceptions or narrowing
    conditions, or in report-only mode. Liten grad: no such policy.
    #>
    [MaesterTest(
        Id = 'MP.NSM.1012',
        Title = 'Conditional Access krever en forvaltet enhet for tilgang til tjenestene',
        Product = 'entra',
        Feature = 'conditional-access',
        Area = 'access-control',
        ResourceType = 'ConditionalAccessPolicy',
        Severity = 'Medium',
        UserImpact = 'High',
        ImplementationCost = 'Medium',
        Control = ('nsm-gp-ikt:2.2.6'),
        Mitre = 'T1078.004',
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
    $deviceControls = 'compliantDevice', 'domainJoinedDevice'
    $rows = foreach ($p in Get-MtConditionalAccessPolicy) {
        $grant = $p.grantControls
        $controls = @($grant.builtInControls | Where-Object { $_ })
        if (-not @($controls | Where-Object { $_ -in $deviceControls }).Count) { continue }
        # The device is required when every alternative is a device control, or the controls are joined with AND.
        $others = @($controls | Where-Object { $_ -notin $deviceControls }).Count + $(if ($grant.authenticationStrength.id) { 1 } else { 0 })
        $required = $others -eq 0 -or $grant.operator -eq 'AND'
        $scope = Get-MtNsmCaScope -Policy $p -Excluded $excluded
        $apps = @($p.conditions.applications.includeApplications)
        $broadApps = $scope.AllApps -or $apps -contains 'Office365'
        $limits = @($scope.Narrowing) + @(if (-not $required) { 'kan oppfylles uten forvaltet enhet' })
        [pscustomobject]@{
            Policy        = $p.displayName
            State         = $p.state
            Brukere       = if ($scope.AllUsers) { 'Alle' } else { 'Utvalgte' }
            Apper         = if ($scope.AllApps) { 'Alle' } elseif ($apps -contains 'Office365') { 'Office 365' } else { 'Utvalgte' }
            Unntak        = $scope.Exceptions
            Begrensninger = $limits -join ', '
            Full          = $scope.AllUsers -and $broadApps -and $scope.Exceptions -le 2 -and $limits.Count -eq 0
        }
    }
    $rows = @($rows)

    if ($rows | Where-Object { $_.State -eq 'enabled' -and $_.Full }) {
        $level = 'H'; $summary = 'En aktivert policy krever en forvaltet enhet for alle brukere, med høyst to unntak og uten vilkår som begrenser den.'
    } elseif ($rows) {
        $level = 'M'; $summary = 'Policyer krever en forvaltet enhet, men bare for noen brukere eller apper, med mange unntak eller begrensende vilkår, eller i report-only.'
    } else {
        $level = 'L'; $summary = 'Ingen policy krever en compliant enhet eller en hybrid joined enhet.'
    }
    Complete-MtNsmResult -Scope $nsmScope -Level $level -Summary $summary -Details (ConvertTo-MtNsmTable -InputObject $rows -Property Policy, State, Brukere, Apper, Unntak, Begrensninger)
}
