function Test-MtNsmUserConsent {
    <#
    .SYNOPSIS
    Checks whether users can consent to applications on their own.

    .DESCRIPTION
    Høy grad: users cannot consent; requests go through admin consent. Moderat grad: users can consent only to
    apps from verified publishers with low-risk permissions. Liten grad: users can consent to any app.
    #>
    [MaesterTest(
        Id = 'MP.NSM.1009',
        Title = 'Brukere kan ikke gi samtykke til ukjente apper',
        Product = 'entra',
        Feature = 'app-consent',
        Area = 'applications',
        ResourceType = 'Policy',
        Severity = 'High',
        UserImpact = 'Low',
        ImplementationCost = 'Low',
        Control = ('nsm-gp-ikt:2.6.4'),
        Mitre = ('T1528', 'T1566.002'),
        Service = 'Graph',
        Permission = 'Graph:Scope:Policy.Read.All',
        Tag = ('NSM', 'NSM-Identitet'),
        Author = 'alventech'
    )]
    [CmdletBinding()]
    [OutputType([bool])]
    param()

    $nsmScope = 'Entra ID-tenanten'

    $policy = Invoke-MtGraphRequest -RelativeUri 'policies/authorizationPolicy' -ApiVersion v1.0
    $grants = @($policy.defaultUserRolePermissions.permissionGrantPoliciesAssigned | Where-Object { $_ -like 'ManagePermissionGrantsForSelf.*' })

    if ($grants -match 'microsoft-user-default-legacy') {
        $level = 'L'; $summary = 'Brukere kan gi samtykke til alle apper.'
    } elseif ($grants) {
        $level = 'M'; $summary = "Brukere kan gi samtykke etter policyen $($grants -replace 'ManagePermissionGrantsForSelf\.', '' -join ', ')."
    } else {
        $level = 'H'; $summary = 'Brukere kan ikke gi samtykke til apper på egen hånd.'
    }
    Complete-MtNsmResult -Scope $nsmScope -Level $level -Summary $summary
}
