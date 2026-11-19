function Test-MtNsmAttackSimulation {
    <#
    .SYNOPSIS
    Checks that phishing simulations have been run recently.

    .DESCRIPTION
    Høy grad: a simulation launched in the last 90 days. Moderat grad: in the last year. Liten grad: none.
    #>
    [MaesterTest(
        Id = 'MP.NSM.2003',
        Title = 'Phishing-simulering er kjørt siste kvartal',
        Product = 'defender',
        Feature = 'anti-phishing',
        Area = 'email-protection',
        ResourceType = 'Tenant',
        Severity = 'Medium',
        UserImpact = 'Low',
        ImplementationCost = 'Low',
        Control = ('nsm-varsel-2026:V7'),
        Service = 'Graph',
        License = 'THREAT_INTELLIGENCE',
        Permission = 'Graph:Scope:AttackSimulation.Read.All',
        Tag = ('NSM', 'NSM-Virksomhet'),
        Author = 'alventech'
    )]
    [CmdletBinding()]
    [OutputType([bool])]
    param()

    $nsmScope = 'Ansatte med postboks i Microsoft 365'

    $now = [datetime]::UtcNow
    try {
        $all = @(Invoke-MtGraphRequest -RelativeUri 'security/attackSimulation/simulations' -Select 'displayName,status,launchDateTime' -ApiVersion v1.0)
    } catch {
        # Usually AttackSimulation.Read.All, which Connect-Maester does not ask for.
        if (Test-MtNsmAccessDenied $_) { Add-MtTestResultDetail -SkippedBecause NotAuthorized; return $null }
        throw
    }
    # Only simulations that have started count; a scheduled or draft simulation has not reached anyone yet.
    $simulations = @($all | Where-Object { $_.launchDateTime -and $_.status -in 'running', 'succeeded' -and [datetime]$_.launchDateTime -le $now } |
        Sort-Object { [datetime]$_.launchDateTime } -Descending)
    $last = if ($simulations) { [datetime]$simulations[0].launchDateTime } else { $null }

    if ($last -and $last -gt $now.AddDays(-90)) {
        $level = 'H'; $summary = "Siste simulering startet $($last.ToString('yyyy-MM-dd'))."
    } elseif ($last -and $last -gt $now.AddDays(-365)) {
        $level = 'M'; $summary = "Siste simulering startet $($last.ToString('yyyy-MM-dd')), mer enn 90 dager siden."
    } else {
        $level = 'L'; $summary = 'Ingen phishing-simulering er kjørt det siste året.'
    }
    $rows = $simulations | Select-Object -First 10 | ForEach-Object { [pscustomobject]@{ Simulering = $_.displayName; Status = $_.status; Startet = ([datetime]$_.launchDateTime).ToString('yyyy-MM-dd') } }
    Complete-MtNsmResult -Scope $nsmScope -Level $level -Summary $summary -Details (ConvertTo-MtNsmTable -InputObject @($rows) -Property Simulering, Status, Startet)
}
