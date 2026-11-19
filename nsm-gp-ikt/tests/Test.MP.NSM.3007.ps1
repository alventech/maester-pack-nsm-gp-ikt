function Test-MtNsmSupportedWindowsVersion {
    <#
    .SYNOPSIS
    Checks that managed Windows devices run a supported Windows version.

    .DESCRIPTION
    A device is supported when its build is at least the NsmGpIkt.MinimumWindowsBuild setting (by default 26100,
    Windows 11 24H2). Høy grad: all devices. Moderat grad: at least 90 %. Liten grad: fewer.
    #>
    [MaesterTest(
        Id = 'MP.NSM.3007',
        Title = 'Windows-enhetene kjører en versjon med støtte',
        Product = 'intune',
        Feature = 'device-compliance',
        Area = 'devices',
        ResourceType = 'Device',
        Severity = 'High',
        UserImpact = 'Medium',
        ImplementationCost = 'Medium',
        Control = ('nsm-gp-ikt:2.1.2'),
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

    $minimum = [int](Get-MtSetting -Name 'NsmGpIkt.MinimumWindowsBuild' -Default 26100)
    # Builds below the minimum that the organisation runs under longer support, such as Windows LTSC.
    $allowed = @(Get-MtSetting -Name 'NsmGpIkt.AllowedWindowsBuilds' -Default @() | ForEach-Object { [int]$_ })
    $devices = Get-MtNsmWindowsDevice
    if ($devices.Count -eq 0) {
        Add-MtTestResultDetail -SkippedBecause Custom -SkippedCustomReason 'Ingen Windows-enheter er forvaltet av Intune.'
        return $null
    }
    # osVersion is 10.0.<build>.<revision>. A version that cannot be read counts as unsupported.
    $old = @($devices | Where-Object {
        $build = 0
        $parts = "$($_.osVersion)".Split('.')
        -not ($parts.Count -ge 3 -and [int]::TryParse($parts[2], [ref]$build)) -or ($build -lt $minimum -and $build -notin $allowed)
    })
    $share = 1 - $old.Count / $devices.Count
    $rows = $old | Sort-Object osVersion | ForEach-Object { [pscustomobject]@{ Enhet = $_.deviceName; Versjon = $_.osVersion } }
    $also = if ($allowed) { " eller et godkjent bygg ($($allowed -join ', '))" } else { '' }
    Complete-MtNsmResult -Scope $nsmScope -Level (Get-MtNsmShareLevel -Share $share -High 1 -Moderate 0.9) `
        -Summary "$(Format-MtNsmPercent $share) av $(Format-MtNsmCount $devices.Count Windows-enhet Windows-enheter) har bygg $minimum eller nyere$also." `
        -Details (ConvertTo-MtNsmTable -InputObject @($rows) -Property Enhet, Versjon)
}
