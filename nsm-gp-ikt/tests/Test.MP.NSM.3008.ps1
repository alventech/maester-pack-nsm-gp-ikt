function Test-MtNsmFirewallPolicy {
    <#
    .SYNOPSIS
    Checks that a Windows Firewall policy is assigned to the Windows clients by Intune.

    .DESCRIPTION
    Looks for assigned firewall policies in Intune endpoint security, current or older (intents). Firewall rule policies alone do not count.
    Høy grad: assigned to all devices or all users. Moderat grad: assigned to groups only. Liten grad: not assigned.
    An assigned policy shows central management, not the state of each device: the link to NSM is partial.
    #>
    [MaesterTest(
        Id = 'MP.NSM.3008',
        Title = 'Brannmuren på Windows-klientene styres av Intune',
        Product = 'intune',
        Feature = 'endpoint-security',
        Area = 'devices',
        ResourceType = 'Tenant',
        Severity = 'Medium',
        UserImpact = 'Medium',
        ImplementationCost = 'Medium',
        Control = ('nsm-gp-ikt:2.4.4'),
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

    $rows = @(Get-MtNsmEndpointPolicy -Kind Firewall)
    $level = Get-MtNsmAssignmentLevel -Rows $rows
    $summary = switch ($level) {
        'H' { 'En brannmurpolicy er tildelt alle enheter.' }
        'M' { "$(Format-MtNsmCount $rows.Count brannmurpolicy brannmurpolicyer) er tildelt, men bare til grupper." }
        'L' { 'Ingen brannmurpolicy er tildelt.' }
    }
    Complete-MtNsmResult -Scope $nsmScope -Level $level -Summary $summary -Details (ConvertTo-MtNsmTable -InputObject $rows -Property Policy, Type, Tildelt)
}
