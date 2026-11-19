function Test-MtNsmAttackSurfaceReduction {
    <#
    .SYNOPSIS
    Checks that attack surface reduction rules are assigned to the Windows clients by Intune.

    .DESCRIPTION
    Looks for assigned attack surface reduction policies in Intune endpoint security, current or older (intents).
    Høy grad: assigned to all devices or all users. Moderat grad: assigned to groups only. Liten grad: not assigned.
    An assigned policy shows central management, not the state of each device: the link to NSM is partial.
    #>
    [MaesterTest(
        Id = 'MP.NSM.3004',
        Title = 'Attack surface reduction-regler (ASR) er tildelt Windows-klientene',
        Product = 'intune',
        Feature = 'endpoint-security',
        Area = 'devices',
        ResourceType = 'Tenant',
        Severity = 'High',
        UserImpact = 'Medium',
        ImplementationCost = 'Medium',
        Control = ('nsm-gp-ikt:3.1.3', 'nsm-gp-ikt:2.3.2'),
        Mitre = ('T1003.001', 'T1546.003', 'T1068'),
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

    $rows = @(Get-MtNsmEndpointPolicy -Kind Asr)
    $level = Get-MtNsmAssignmentLevel -Rows $rows
    $summary = switch ($level) {
        'H' { 'En ASR-policy er tildelt alle enheter.' }
        'M' { "$(Format-MtNsmCount $rows.Count ASR-policy ASR-policyer) er tildelt, men bare til grupper." }
        'L' { 'Ingen ASR-policy er tildelt.' }
    }
    Complete-MtNsmResult -Scope $nsmScope -Level $level -Summary $summary -Details (ConvertTo-MtNsmTable -InputObject $rows -Property Policy, Type, Tildelt)
}
