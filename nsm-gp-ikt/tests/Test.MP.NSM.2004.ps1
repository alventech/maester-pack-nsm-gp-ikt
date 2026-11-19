function Test-MtNsmDefenderForIdentity {
    <#
    .SYNOPSIS
    Checks that Defender for Identity sensors are installed on the domain controllers.

    .DESCRIPTION
    Reads the Secure Score control that reports a missing Defender for Identity deployment. Høy grad: the control
    has full score. Liten grad: the sensor is missing. Skipped when the tenant has no such control.
    #>
    [MaesterTest(
        Id = 'MP.NSM.2004',
        Title = 'Defender for Identity overvåker domenekontrollerne',
        Product = 'defender',
        Feature = 'defender-for-identity',
        Area = 'logging-and-detection',
        ResourceType = 'Tenant',
        Severity = 'High',
        UserImpact = 'Low',
        ImplementationCost = 'Medium',
        Control = ('nsm-gp-ikt:3.2.3', 'nsm-gp-ikt:3.2.4'),
        Service = 'Graph',
        License = 'ATA',
        Permission = ('Graph:Scope:SecurityEvents.Read.All', 'Graph:Scope:Directory.Read.All'),
        Tag = ('NSM', 'NSM-On-prem'),
        Author = 'alventech'
    )]
    [CmdletBinding()]
    [OutputType([bool])]
    param()

    $nsmScope = 'Domenekontrollere i lokal Active Directory'

    try {
        $org = @(Invoke-MtGraphRequest -RelativeUri 'organization' -Select 'onPremisesSyncEnabled' -ApiVersion v1.0)[0]
        if (-not $org.onPremisesSyncEnabled) {
            Add-MtTestResultDetail -SkippedBecause NotApplicable -Result 'Tenanten synkroniserer ikke fra lokal Active Directory, så det er ingen domenekontrollere å overvåke.'
            return $null
        }
        $score = Get-MtNsmSecureScore
    } catch {
        # Usually SecurityEvents.Read.All, which Connect-Maester does not ask for.
        if (Test-MtNsmAccessDenied $_) { Add-MtTestResultDetail -SkippedBecause NotAuthorized; return $null }
        throw
    }
    $control = $score.controlScores | Where-Object controlName -EQ 'AATP_DefenderForIdentityIsNotInstalled' | Select-Object -First 1
    if (-not $control) {
        Add-MtTestResultDetail -SkippedBecause Custom -SkippedCustomReason 'Secure Score har ingen kontroll for Defender for Identity i denne tenanten.'
        return $null
    }
    if ([double]$control.scoreInPercentage -ge 100) {
        Complete-MtNsmResult -Scope $nsmScope -Level H -Summary 'Defender for Identity er installert.'
    } else {
        Complete-MtNsmResult -Scope $nsmScope -Level L -Summary 'Secure Score melder at Defender for Identity ikke er installert på domenekontrollerne.'
    }
}
