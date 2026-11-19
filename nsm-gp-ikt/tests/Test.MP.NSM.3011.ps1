function Test-MtNsmDeviceCompliance {
    <#
    .SYNOPSIS
    Checks the share of Windows devices that are compliant with the Intune compliance policies.

    .DESCRIPTION
    Høy grad: at least 95 % compliant. Moderat grad: at least 80 %. Liten grad: lower. Co-managed devices whose
    compliance Configuration Manager evaluates are left out. Høy grad is not given when devices without a
    compliance policy count as compliant.
    #>
    [MaesterTest(
        Id = 'MP.NSM.3011',
        Title = 'Windows-enhetene oppfyller virksomhetens compliance policies',
        Product = 'intune',
        Feature = 'device-compliance',
        Area = 'devices',
        ResourceType = 'Device',
        Severity = 'Medium',
        UserImpact = 'Medium',
        ImplementationCost = 'Low',
        Control = ('nsm-gp-ikt:2.3.5'),
        Service = 'Graph',
        License = 'INTUNE_A',
        Permission = ('Graph:Scope:DeviceManagementManagedDevices.Read.All', 'Graph:Scope:DeviceManagementConfiguration.Read.All'),
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
    # Co-managed devices whose compliance Configuration Manager evaluates have no Intune compliance state.
    $byIntune = @($devices | Where-Object complianceState -NE 'configManager')
    if ($byIntune.Count -eq 0) {
        Add-MtTestResultDetail -SkippedBecause Custom -SkippedCustomReason 'Configuration Manager vurderer compliance for alle Windows-enhetene, så Intune har ingen compliance-status for dem.'
        return $null
    }
    $compliant = @($byIntune | Where-Object complianceState -EQ 'compliant').Count / $byIntune.Count
    $level = Get-MtNsmShareLevel -Share $compliant -High 0.95 -Moderate 0.8

    $summary = "$(Format-MtNsmPercent $compliant) av $(Format-MtNsmCount $byIntune.Count Windows-enhet Windows-enheter) er compliant."
    if ($byIntune.Count -lt $devices.Count) { $summary += " $($devices.Count - $byIntune.Count) co-managed enheter får compliance-status fra Configuration Manager og er holdt utenfor." }
    try {
        $secure = (Invoke-MtGraphRequest -RelativeUri 'deviceManagement' -Select 'settings' -ApiVersion beta).settings.secureByDefault
    } catch {
        if (-not (Test-MtNsmAccessDenied $_)) { throw }
        $secure = $null
        $summary += ' Innstillingen for enheter uten compliance policy kunne ikke leses.'
    }
    if ($secure -eq $false) {
        # Devices without a compliance policy then count as compliant, so the share says less.
        if ($level -eq 'H') { $level = 'M' }
        $summary += ' Enheter uten compliance policy regnes som compliant i denne tenanten.'
    }

    $rows = $byIntune | Where-Object complianceState -NE 'compliant' | Sort-Object deviceName |
        ForEach-Object { [pscustomobject]@{ Enhet = $_.deviceName; Compliance = $_.complianceState } }
    Complete-MtNsmResult -Scope $nsmScope -Level $level -Summary $summary -Details (ConvertTo-MtNsmTable -InputObject @($rows) -Property Enhet, Compliance)
}
