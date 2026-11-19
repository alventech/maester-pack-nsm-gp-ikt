function Test-MtNsmIdentityRecommendation {
    <#
    .SYNOPSIS
    Lists the active Entra recommendations with high priority.

    .DESCRIPTION
    Høy grad: no active high-priority recommendation. Moderat grad: one or two. Liten grad: more.
    #>
    [MaesterTest(
        Id = 'MP.NSM.1010',
        Title = 'Ingen aktive høyprioritets anbefalinger i Entra',
        Product = 'entra',
        Feature = 'recommendations',
        Area = 'infrastructure',
        ResourceType = 'Tenant',
        Severity = 'Medium',
        UserImpact = 'Low',
        ImplementationCost = 'Low',
        Service = 'Graph',
        Permission = 'Graph:Scope:DirectoryRecommendations.Read.All',
        Tag = ('NSM', 'NSM-Identitet', 'NSM-Indikator'),
        Author = 'alventech'
    )]
    [CmdletBinding()]
    [OutputType([bool])]
    param()

    $nsmScope = 'Entra ID-tenanten'

    try {
        $active = @(Invoke-MtGraphRequest -RelativeUri 'directory/recommendations' -Filter "status eq 'active'" -Select 'displayName,priority,category,impactType' -ApiVersion beta)
    } catch {
        if (Test-MtNsmAccessDenied $_) { Add-MtTestResultDetail -SkippedBecause NotAuthorized; return $null }
        throw
    }
    $high = @($active | Where-Object priority -EQ 'high')
    $rows = $active | Sort-Object @{ e = { @{ high = 0; medium = 1; low = 2 }[$_.priority] } }, displayName |
        ForEach-Object { [pscustomobject]@{ Anbefaling = $_.displayName; Prioritet = $_.priority; Gjelder = $_.impactType } }

    $level = if ($high.Count -eq 0) { 'H' } elseif ($high.Count -le 2) { 'M' } else { 'L' }
    Complete-MtNsmResult -Scope $nsmScope -Level $level -Summary "$(Format-MtNsmCount $active.Count 'aktiv anbefaling' 'aktive anbefalinger'), $($high.Count) med høy prioritet." `
        -Details (ConvertTo-MtNsmTable -InputObject @($rows) -Property Anbefaling, Prioritet, Gjelder)
}
