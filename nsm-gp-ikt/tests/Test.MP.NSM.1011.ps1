function Test-MtNsmLocalAdminOnJoin {
    <#
    .SYNOPSIS
    Checks that users who join a device to Entra ID do not become local administrator on it.

    .DESCRIPTION
    Reads the device settings in Entra ID (the device registration policy).
    Høy grad: no registering user becomes local administrator. Moderat grad: selected users or groups do.
    Liten grad: every user who joins a device becomes local administrator on it.
    #>
    [MaesterTest(
        Id = 'MP.NSM.1011',
        Title = 'Brukere blir ikke lokal administrator når de kobler en enhet til Entra ID',
        Product = 'entra',
        Feature = 'devices',
        Area = 'privileged-access',
        ResourceType = 'Tenant',
        Severity = 'High',
        UserImpact = 'Medium',
        ImplementationCost = 'Low',
        Control = ('nsm-gp-ikt:2.6.4'),
        Mitre = 'T1078.004',
        Service = 'Graph',
        Permission = 'Graph:Scope:Policy.Read.All',
        Tag = ('NSM', 'NSM-Endepunkt'),
        Author = 'alventech'
    )]
    [CmdletBinding()]
    [OutputType([bool])]
    param()

    $nsmScope = 'Windows-enheter som kobles til Entra ID'

    try {
        $policy = Get-MtNsmDeviceRegistrationPolicy
    } catch {
        if (Test-MtNsmAccessDenied $_) { Add-MtTestResultDetail -SkippedBecause NotAuthorized; return $null }
        throw
    }
    $join = $policy.azureADJoin
    if ([string]$join.allowedToJoin.'@odata.type' -like '*noDeviceRegistrationMembership') {
        Add-MtTestResultDetail -SkippedBecause NotApplicable -Result 'Ingen brukere kan koble enheter til Entra ID i denne tenanten.'
        return $null
    }
    $who = $join.localAdmins.registeringUsers
    $type = [string]$who.'@odata.type'
    if ($type -like '*noDeviceRegistrationMembership') {
        $level = 'H'; $summary = 'Brukeren som kobler en enhet til Entra ID, blir ikke lokal administrator på den.'
    } elseif ($type -like '*enumeratedDeviceRegistrationMembership') {
        $count = @($who.users).Count + @($who.groups).Count
        $level = 'M'; $summary = "$count utvalgte brukere eller grupper blir lokal administrator på enheter de kobler til Entra ID."
    } elseif ($type -like '*allDeviceRegistrationMembership') {
        $level = 'L'; $summary = 'Alle brukere blir lokal administrator på enheter de kobler til Entra ID.'
    } else {
        throw "Unknown registeringUsers type in the device registration policy: '$type'."
    }
    $rows = @(
        [pscustomobject]@{ Innstilling = 'Brukeren som kobler til enheten, blir lokal administrator'; Verdi = @{ H = 'Ingen'; M = 'Utvalgte'; L = 'Alle' }[$level] }
        [pscustomobject]@{ Innstilling = 'Global Administrator-rollen er lokal administrator (vurderes ikke)'; Verdi = if ($join.localAdmins.enableGlobalAdmins) { 'Ja' } else { 'Nei' } }
    )
    Complete-MtNsmResult -Scope $nsmScope -Level $level -Summary $summary -Details (ConvertTo-MtNsmTable -InputObject $rows -Property Innstilling, Verdi)
}
