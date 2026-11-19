function Test-MtNsmOutlookAddin {
    <#
    .SYNOPSIS
    Checks that users cannot install Outlook add-ins themselves.

    .DESCRIPTION
    Reads the Microsoft Secure Score recommendation exo_outlookaddins and Microsoft's own evidence for it.
    Høy grad: the recommendation is met. Moderat grad: partly met. Liten grad: not met.
    #>
    [MaesterTest(
        Id = 'MP.NSM.2005',
        Title = 'Brukere kan ikke installere Outlook-tillegg selv',
        Product = 'exchange',
        Feature = 'secure-score',
        Area = 'applications',
        ResourceType = 'Tenant',
        Severity = 'Medium',
        UserImpact = 'Low',
        ImplementationCost = 'Low',
        Control = ('nsm-gp-ikt:2.8.4'),
        Mitre = ('T1137.006', 'T1114.002'),
        Service = 'Graph',
        Permission = 'Graph:Scope:SecurityEvents.Read.All',
        Tag = ('NSM', 'NSM-M365'),
        Author = 'alventech'
    )]
    [CmdletBinding()]
    [OutputType([bool])]
    param()

    $nsmScope = 'Outlook i Exchange Online'

    try {
        $score = Get-MtNsmSecureScore
    } catch {
        # Usually SecurityEvents.Read.All, which Connect-Maester does not ask for.
        if (Test-MtNsmAccessDenied $_) { Add-MtTestResultDetail -SkippedBecause NotAuthorized; return $null }
        throw
    }
    $control = $score.controlScores | Where-Object controlName -EQ 'exo_outlookaddins' | Select-Object -First 1
    if (-not $control) {
        Add-MtTestResultDetail -SkippedBecause Custom -SkippedCustomReason 'Secure Score har ingen anbefaling om Outlook-tillegg for denne tenanten.'
        return $null
    }
    $met = [double]$control.scoreInPercentage
    # Microsoft's status is sometimes HTML.
    $status = ([string]$control.implementationStatus -replace '<[^>]+>', ' ' -replace '&nbsp;', ' ' -replace '\s+', ' ').Trim()
    if ($met -ge 100) {
        $level = 'H'; $summary = 'Brukere kan ikke installere Outlook-tillegg selv.'
    } elseif ($met -gt 0) {
        $level = 'M'; $summary = 'Noen brukere kan installere Outlook-tillegg selv.'
    } else {
        $level = 'L'; $summary = 'Brukere kan installere Outlook-tillegg selv.'
    }
    if ($status) { $summary += " Secure Score: $([math]::Floor($met)) % oppfylt. Microsofts tekst: «$status»." }
    Complete-MtNsmResult -Scope $nsmScope -Level $level -Summary $summary
}
