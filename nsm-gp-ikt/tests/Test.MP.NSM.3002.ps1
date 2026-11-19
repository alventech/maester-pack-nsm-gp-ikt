function Test-MtNsmWindowsUpdate {
    <#
    .SYNOPSIS
    Checks that Windows update rings are assigned and that devices check in.

    .DESCRIPTION
    Høy grad: an assigned update ring, and at least 95 % of Windows devices synced in the last 7 days.
    Moderat grad: an assigned ring and at least 70 %. Liten grad: no assigned ring or fewer devices.
    #>
    [MaesterTest(
        Id = 'MP.NSM.3002',
        Title = 'Windows-oppdateringer styres sentralt, og enhetene synkroniserer med Intune',
        Product = 'intune',
        Feature = 'device-configuration',
        Area = 'devices',
        ResourceType = 'Tenant',
        Severity = 'High',
        UserImpact = 'Medium',
        ImplementationCost = 'Low',
        Control = ('nsm-gp-ikt:2.3.1'),
        Service = 'Graph',
        License = 'INTUNE_A',
        Permission = ('Graph:Scope:DeviceManagementConfiguration.Read.All', 'Graph:Scope:DeviceManagementManagedDevices.Read.All'),
        Tag = ('NSM', 'NSM-Endepunkt'),
        Author = 'alventech'
    )]
    [CmdletBinding()]
    [OutputType([bool])]
    param()

    $nsmScope = 'Windows-klienter i Intune'

    $rings = @(Invoke-MtGraphRequest -RelativeUri "deviceManagement/deviceConfigurations?`$expand=assignments" -ApiVersion beta |
        Where-Object { $_.'@odata.type' -eq '#microsoft.graph.windowsUpdateForBusinessConfiguration' -and (Test-MtNsmAssigned $_.assignments) })
    $devices = Get-MtNsmWindowsDevice
    if ($devices.Count -eq 0) {
        Add-MtTestResultDetail -SkippedBecause Custom -SkippedCustomReason 'Ingen Windows-enheter er forvaltet av Intune.'
        return $null
    }

    $since = [datetime]::UtcNow.AddDays(-7)
    $recent = @($devices | Where-Object { $_.lastSyncDateTime -and [datetime]$_.lastSyncDateTime -gt $since })
    $share = $recent.Count / $devices.Count
    $level = if (-not $rings) { 'L' } else { Get-MtNsmShareLevel -Share $share -High 0.95 -Moderate 0.7 }
    $summary = "$(Format-MtNsmCount $rings.Count 'tildelt update ring' 'tildelte update rings'). $(Format-MtNsmPercent $share) av $(Format-MtNsmCount $devices.Count Windows-enhet Windows-enheter) har synkronisert de siste 7 dagene."
    $stale = $devices | Where-Object { -not $_.lastSyncDateTime -or [datetime]$_.lastSyncDateTime -le $since } | Sort-Object lastSyncDateTime |
        ForEach-Object { [pscustomobject]@{ Enhet = $_.deviceName; Versjon = $_.osVersion; 'Siste synkronisering' = if ($_.lastSyncDateTime) { ([datetime]$_.lastSyncDateTime).ToString('yyyy-MM-dd') } else { 'aldri' } } }
    Complete-MtNsmResult -Scope $nsmScope -Level $level -Summary $summary -Details (ConvertTo-MtNsmTable -InputObject @($stale) -Property Enhet, Versjon, 'Siste synkronisering')
}
