function Test-MtNsmSecurityBaseline {
    <#
    .SYNOPSIS
    Checks that a security baseline is assigned to the Windows clients by Intune.

    .DESCRIPTION
    Looks for an assigned Intune security baseline, or a settings catalog policy whose name matches the NsmGpIkt.BaselinePolicyPattern setting (by default CIS or baseline).
    Høy grad: assigned to all devices or all users. Moderat grad: assigned to groups only. Liten grad: not assigned.
    An assigned policy shows central management, not the state of each device: the link to NSM is partial.
    #>
    [MaesterTest(
        Id = 'MP.NSM.3010',
        Title = 'Windows-klientene har en standard sikkerhetskonfigurasjon (security baseline)',
        Product = 'intune',
        Feature = 'endpoint-security',
        Area = 'devices',
        ResourceType = 'Tenant',
        Severity = 'Medium',
        UserImpact = 'Medium',
        ImplementationCost = 'Medium',
        Control = ('nsm-gp-ikt:2.3.4'),
        Service = 'Graph',
        License = 'INTUNE_A',
        Permission = 'Graph:Scope:DeviceManagementConfiguration.Read.All',
        Tag = ('NSM', 'NSM-Endepunkt'),
        Author = 'alventech'
    )]
    [CmdletBinding()]
    [OutputType([bool])]
    param()

    $nsmScope = 'Windows-klienter i Intune'

    $rows = @(Get-MtNsmEndpointPolicy -Kind Baseline)
    $level = Get-MtNsmAssignmentLevel -Rows $rows
    $summary = switch ($level) {
        'H' { 'En security baseline er tildelt alle enheter.' }
        'M' { "$(Format-MtNsmCount $rows.Count 'security baseline' 'security baselines') er tildelt, men bare til grupper." }
        'L' { 'Ingen security baseline er tildelt.' }
    }
    Complete-MtNsmResult -Scope $nsmScope -Level $level -Summary $summary -Details (ConvertTo-MtNsmTable -InputObject $rows -Property Policy, Type, Tildelt)
}
