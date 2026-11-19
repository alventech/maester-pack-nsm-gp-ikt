function Test-MtNsmApplicationControl {
    <#
    .SYNOPSIS
    Checks that application control is deployed to Windows devices.

    .DESCRIPTION
    Høy grad: an assigned App Control for Business policy. Moderat grad: AppLocker deployed through a custom
    OMA-URI profile. Liten grad: neither.
    #>
    [MaesterTest(
        Id = 'MP.NSM.3003',
        Title = 'Applikasjonskontroll hindrer ukjent programvare',
        Product = 'intune',
        Feature = 'endpoint-security',
        Area = 'devices',
        ResourceType = 'Tenant',
        Severity = 'High',
        UserImpact = 'High',
        ImplementationCost = 'High',
        Control = ('nsm-gp-ikt:2.3.2'),
        Mitre = 'T1204.002',
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

    $appControl = @(Invoke-MtGraphRequest -RelativeUri "deviceManagement/configurationPolicies?`$expand=assignments" -ApiVersion beta |
        Where-Object { $_.templateReference.templateFamily -eq 'endpointSecurityApplicationControl' -and (Test-MtNsmAssigned $_.assignments) })

    $custom = @(Invoke-MtGraphRequest -RelativeUri "deviceManagement/deviceConfigurations?`$expand=assignments" -ApiVersion beta |
        Where-Object { $_.'@odata.type' -eq '#microsoft.graph.windows10CustomConfiguration' -and (Test-MtNsmAssigned $_.assignments) })
    $wdac = @(); $appLocker = @()
    foreach ($c in $custom) {
        # The list does not return the OMA-URI settings; the profile itself does.
        $uris = @((Invoke-MtGraphRequest -RelativeUri "deviceManagement/deviceConfigurations/$($c.id)" -ApiVersion beta).omaSettings.omaUri)
        if ($uris -match '/ApplicationControl/') { $wdac += $c } elseif ($uris -match '/AppLocker/') { $appLocker += $c }
    }

    $rows = @($appControl | ForEach-Object { [pscustomobject]@{ Policy = $_.name; Type = 'App Control for Business' } }) +
            @($wdac | ForEach-Object { [pscustomobject]@{ Policy = $_.displayName; Type = 'App Control for Business (OMA-URI)' } }) +
            @($appLocker | ForEach-Object { [pscustomobject]@{ Policy = $_.displayName; Type = 'AppLocker (OMA-URI)' } })
    if ($appControl -or $wdac) {
        $level = 'H'; $summary = 'App Control for Business er tildelt.'
    } elseif ($appLocker) {
        $level = 'M'; $summary = 'AppLocker er satt opp med custom-profil, men ingen App Control for Business-policy.'
    } else {
        $level = 'L'; $summary = 'Ingen applikasjonskontroll er tildelt.'
    }
    Complete-MtNsmResult -Scope $nsmScope -Level $level -Summary $summary -Details (ConvertTo-MtNsmTable -InputObject $rows -Property Policy, Type)
}
