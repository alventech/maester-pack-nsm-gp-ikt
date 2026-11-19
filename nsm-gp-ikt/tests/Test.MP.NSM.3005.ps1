function Test-MtNsmDeviceEncryption {
    <#
    .SYNOPSIS
    Checks the share of Windows devices that are encrypted.

    .DESCRIPTION
    Høy grad: at least 95 % of the Windows devices Intune manages report as encrypted. Moderat grad: at least 80 %.
    Liten grad: lower.
    #>
    [MaesterTest(
        Id = 'MP.NSM.3005',
        Title = 'Windows-enhetene er kryptert',
        Product = 'intune',
        Feature = 'device-compliance',
        Area = 'devices',
        ResourceType = 'Device',
        Severity = 'Medium',
        UserImpact = 'Low',
        ImplementationCost = 'Low',
        Control = ('nsm-gp-ikt:2.7.3'),
        Mitre = 'T1005',
        Service = 'Graph',
        License = 'INTUNE_A',
        Permission = 'Graph:Scope:DeviceManagementManagedDevices.Read.All',
        Tag = ('NSM', 'NSM-Endepunkt'),
        Author = 'alventech'
    )]
    [CmdletBinding()]
    [OutputType([bool])]
    param()

    $nsmScope = 'Windows-klienter i Intune'

    $devices = Get-MtNsmWindowsDevice
    if ($devices.Count -eq 0) {
        Add-MtTestResultDetail -SkippedBecause Custom -SkippedCustomReason 'Ingen Windows-enheter er forvaltet av Intune.'
        return $null
    }
    $encrypted = @($devices | Where-Object isEncrypted).Count / $devices.Count
    $rows = $devices | Where-Object { -not $_.isEncrypted } | Sort-Object deviceName | ForEach-Object { [pscustomobject]@{ Enhet = $_.deviceName; Kryptert = 'Nei' } }
    Complete-MtNsmResult -Scope $nsmScope -Level (Get-MtNsmShareLevel -Share $encrypted -High 0.95 -Moderate 0.8) `
        -Summary "$(Format-MtNsmPercent $encrypted) av $(Format-MtNsmCount $devices.Count Windows-enhet Windows-enheter) er kryptert." `
        -Details (ConvertTo-MtNsmTable -InputObject @($rows) -Property Enhet, Kryptert)
}
