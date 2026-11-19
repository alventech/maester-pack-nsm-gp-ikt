function Test-MtNsmIntuneLaps {
    <#
    .SYNOPSIS
    Checks that Windows LAPS is assigned by Intune to all devices, and turned on in Entra ID. Local group
    policies are listed, not scored.

    .DESCRIPTION
    Høy grad: an assigned Windows LAPS policy targets all devices. Moderat grad: LAPS is assigned to some groups
    only. Liten grad: no assigned LAPS policy, or LAPS is turned off in Entra ID in a cloud-only tenant, where
    the policies then have nowhere to store the password.
    #>
    [MaesterTest(
        Id = 'MP.NSM.3001',
        Title = 'Windows LAPS styres av Intune på alle enheter',
        Product = 'intune',
        Feature = 'endpoint-security',
        Area = 'privileged-access',
        ResourceType = 'Tenant',
        Severity = 'High',
        UserImpact = 'Low',
        ImplementationCost = 'Low',
        Control = ('nsm-gp-ikt:2.3.7'),
        Mitre = ('T1078.003', 'T1021'),
        Service = 'Graph',
        License = 'INTUNE_A',
        Permission = ('Graph:Scope:DeviceManagementConfiguration.Read.All', 'Graph:Scope:Policy.Read.All', 'Graph:Scope:Directory.Read.All'),
        Tag = ('NSM', 'NSM-Endepunkt'),
        Author = 'alventech'
    )]
    [CmdletBinding()]
    [OutputType([bool])]
    param()

    $nsmScope = 'Windows-klienter i Intune'

    $policies = @(Invoke-MtGraphRequest -RelativeUri "deviceManagement/configurationPolicies?`$expand=assignments" -ApiVersion beta)
    $account = @($policies | Where-Object { $_.templateReference.templateFamily -eq 'endpointSecurityAccountProtection' })
    # LAPS can also be set in a settings catalog policy, which has no template; its settings name the LAPS CSP.
    $catalog = @($policies | Where-Object { $_.templateReference.templateFamily -eq 'none' -and (Test-MtNsmAssigned $_.assignments) } | Where-Object {
        $ids = @(Invoke-MtGraphRequest -RelativeUri "deviceManagement/configurationPolicies('$($_.id)')/settings" -ApiVersion beta).settingInstance.settingDefinitionId
        @($ids | Where-Object { $_ -like 'device_vendor_msft_laps_*' }).Count -gt 0
    })

    $rows = foreach ($p in @($account) + @($catalog)) {
        [pscustomobject]@{
            Policy  = $p.name
            Mal     = if ($p.templateReference.templateFamily -eq 'none') { 'Settings catalog (LAPS)' } else { $p.templateReference.templateDisplayName }
            Tildelt = if (Test-MtNsmAllDevicesAssignment $p.assignments) { 'Alle enheter' } elseif (Test-MtNsmAssigned $p.assignments) { 'Grupper' } else { 'Nei' }
        }
    }
    $rows = @($rows)
    $laps = @($rows | Where-Object { $_.Mal -like '*LAPS*' -and $_.Tildelt -ne 'Nei' })

    if ($laps | Where-Object Tildelt -EQ 'Alle enheter') {
        $level = 'H'; $summary = 'Windows LAPS er tildelt alle enheter.'
    } elseif ($laps) {
        $level = 'M'; $summary = "Windows LAPS er tildelt i $(Format-MtNsmCount $laps.Count policy policyer), men bare til grupper."
    } else {
        $level = 'L'; $summary = 'Ingen Windows LAPS-policy er tildelt.'
    }

    # A policy cannot store the password in Entra ID while LAPS is off in the tenant's device settings. A hybrid
    # tenant may store it in Active Directory instead, so only a cloud-only tenant is scored down.
    if ($laps) {
        try {
            $enabled = (Get-MtNsmDeviceRegistrationPolicy).localAdminPassword.isEnabled
            $hybrid = [bool]@(Invoke-MtGraphRequest -RelativeUri 'organization' -Select 'onPremisesSyncEnabled' -ApiVersion v1.0)[0].onPremisesSyncEnabled
            if ($enabled -eq $false -and -not $hybrid) {
                $level = 'L'; $summary += ' Men LAPS er slått av i Device settings i Entra ID, så policyene kan ikke lagre passordet der.'
            } elseif ($enabled -eq $false) {
                $summary += ' LAPS er slått av i Device settings i Entra ID: policyene virker bare hvis de lagrer passordet i lokal Active Directory.'
            }
        } catch {
            if (-not (Test-MtNsmAccessDenied $_)) { throw }
            $summary += ' Enhetsinnstillingene i Entra ID kunne ikke leses, så det er ikke sjekket om LAPS er slått på der.'
        }
    }
    Complete-MtNsmResult -Scope $nsmScope -Level $level -Summary $summary -Details (ConvertTo-MtNsmTable -InputObject $rows -Property Policy, Mal, Tildelt)
}
