function Test-MtNsmAntivirusPolicy {
    <#
    .SYNOPSIS
    Checks that a Microsoft Defender Antivirus policy is assigned to the Windows clients by Intune.

    .DESCRIPTION
    Looks for assigned antivirus policies in Intune endpoint security, current or older (intents). Exclusion policies alone do not count.
    Høy grad: assigned to all devices or all users. Moderat grad: assigned to groups only. Liten grad: not assigned.
    An assigned policy shows central management, not the state of each device: the link to NSM is partial.
    #>
    [MaesterTest(
        Id = 'MP.NSM.3009',
        Title = 'Antivirus på Windows-klientene styres sentralt av Intune',
        Product = 'intune',
        Feature = 'endpoint-security',
        Area = 'devices',
        ResourceType = 'Tenant',
        Severity = 'High',
        UserImpact = 'Medium',
        ImplementationCost = 'Medium',
        Control = ('nsm-gp-ikt:3.1.3'),
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

    $rows = @(Get-MtNsmEndpointPolicy -Kind Antivirus)
    $level = Get-MtNsmAssignmentLevel -Rows $rows
    $summary = switch ($level) {
        'H' { 'En antiviruspolicy er tildelt alle enheter.' }
        'M' { "$(Format-MtNsmCount $rows.Count antiviruspolicy antiviruspolicyer) er tildelt, men bare til grupper." }
        'L' { 'Ingen antiviruspolicy er tildelt.' }
    }
    Complete-MtNsmResult -Scope $nsmScope -Level $level -Summary $summary -Details (ConvertTo-MtNsmTable -InputObject $rows -Property Policy, Type, Tildelt)
}
