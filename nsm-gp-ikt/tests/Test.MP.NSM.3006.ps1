function Test-MtNsmDeviceInventory {
    <#
    .SYNOPSIS
    Checks the share of active Windows devices in Entra ID that are managed.

    .DESCRIPTION
    Counts Windows devices in Entra ID that signed in during the last 30 days, and the share of them that are
    managed (by Intune or Configuration Manager). Høy grad: at least 95 %. Moderat grad: at least 80 %.
    Liten grad: lower.
    #>
    [MaesterTest(
        Id = 'MP.NSM.3006',
        Title = 'Aktive Windows-enheter er kjent og forvaltet',
        Product = 'entra',
        Feature = 'devices',
        Area = 'devices',
        ResourceType = 'Device',
        Severity = 'Medium',
        UserImpact = 'Low',
        ImplementationCost = 'Low',
        Control = ('nsm-gp-ikt:1.2.3'),
        Service = 'Graph',
        Permission = 'Graph:Scope:Device.Read.All',
        Tag = ('NSM', 'NSM-Endepunkt'),
        Author = 'alventech'
    )]
    [CmdletBinding()]
    [OutputType([bool])]
    param()

    $nsmScope = 'Windows-enheter i Entra ID'

    $since = [datetime]::UtcNow.AddDays(-30)
    $devices = @(Invoke-MtGraphRequest -RelativeUri 'devices' -Filter "operatingSystem eq 'Windows' and accountEnabled eq true" -Select 'displayName,isManaged,trustType,approximateLastSignInDateTime' -QueryParameters @{ '$top' = 999 } -ApiVersion v1.0 |
        Where-Object { $_.approximateLastSignInDateTime -and [datetime]$_.approximateLastSignInDateTime -gt $since })
    if ($devices.Count -eq 0) {
        Add-MtTestResultDetail -SkippedBecause Custom -SkippedCustomReason 'Ingen aktive Windows-enheter i Entra ID de siste 30 dagene.'
        return $null
    }
    $share = @($devices | Where-Object isManaged).Count / $devices.Count
    $rows = $devices | Where-Object { -not $_.isManaged } | Sort-Object displayName |
        ForEach-Object { [pscustomobject]@{ Enhet = $_.displayName; Type = $_.trustType; 'Sist pålogget' = ([datetime]$_.approximateLastSignInDateTime).ToString('yyyy-MM-dd') } }
    Complete-MtNsmResult -Scope $nsmScope -Level (Get-MtNsmShareLevel -Share $share -High 0.95 -Moderate 0.8) `
        -Summary "$(Format-MtNsmPercent $share) av $(Format-MtNsmCount $devices.Count 'aktiv Windows-enhet' 'aktive Windows-enheter') i Entra ID er forvaltet." `
        -Details (ConvertTo-MtNsmTable -InputObject @($rows) -Property Enhet, Type, 'Sist pålogget')
}
