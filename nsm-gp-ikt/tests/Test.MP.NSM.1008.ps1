function Test-MtNsmGuestAccessReview {
    <#
    .SYNOPSIS
    Checks that access reviews cover guests and supplier access.

    .DESCRIPTION
    Høy grad: an active, recurring access review covers guest users. Moderat grad: access reviews exist, but none
    is a recurring review of guests. Liten grad: no access reviews.
    #>
    [MaesterTest(
        Id = 'MP.NSM.1008',
        Title = 'Gjester og leverandørtilganger gjennomgås jevnlig',
        Product = 'entra',
        Feature = 'identity-governance',
        Area = 'external-access',
        ResourceType = 'Tenant',
        Severity = 'Medium',
        UserImpact = 'Low',
        ImplementationCost = 'Low',
        Control = ('nsm-gp-ikt:2.6.1'),
        Mitre = 'T1078.004',
        Service = 'Graph',
        License = ('AAD_PREMIUM_P2', 'Entra_Identity_Governance'),
        Permission = ('Graph:Scope:AccessReview.Read.All', 'Graph:Scope:Directory.Read.All'),
        Tag = ('NSM', 'NSM-Identitet'),
        Author = 'alventech'
    )]
    [CmdletBinding()]
    [OutputType([bool])]
    param()

    $nsmScope = 'Gjestekontoer i Entra ID'

    try {
        # One guest is enough to know that the tenant has guests.
        $guests = @((Invoke-MtGraphRequest -RelativeUri 'users' -Filter "userType eq 'Guest'" -Select 'id' -QueryParameters @{ '$top' = 1 } -DisablePaging -ApiVersion v1.0).value)
        $reviews = @(Invoke-MtGraphRequest -RelativeUri 'identityGovernance/accessReviews/definitions' -ApiVersion v1.0)
    } catch {
        if (Test-MtNsmAccessDenied $_) { Add-MtTestResultDetail -SkippedBecause NotAuthorized; return $null }
        throw
    }
    if (-not $guests) {
        Add-MtTestResultDetail -SkippedBecause NotApplicable -Result 'Tenanten har ingen gjestebrukere å gjennomgå.'
        return $null
    }

    $rows = foreach ($r in $reviews) {
        $scope = ($r.scope | ConvertTo-Json -Depth 6 -Compress)
        [pscustomobject]@{
            Gjennomgang = $r.displayName
            Status      = $r.status
            Gjester     = if ($scope -match "userType eq 'Guest'") { 'Ja' } else { 'Nei' }
            Gjentas     = if ($r.settings.recurrence.pattern.type) { "$($r.settings.recurrence.pattern.type) / $($r.settings.recurrence.pattern.interval)" } else { 'Nei' }
        }
    }
    $rows = @($rows)
    $good = @($rows | Where-Object { $_.Gjester -eq 'Ja' -and $_.Gjentas -ne 'Nei' -and $_.Status -in 'InProgress', 'NotStarted', 'Initializing' })

    if ($good) {
        $level = 'H'; $summary = 'En gjentakende access review dekker gjester.'
    } elseif ($rows) {
        $level = 'M'; $summary = "$(Format-MtNsmCount $rows.Count 'access review' 'access reviews') finnes, men ingen gjentakende gjennomgang av gjester."
    } else {
        $level = 'L'; $summary = 'Tenanten har gjester, men ingen access reviews er satt opp.'
    }
    Complete-MtNsmResult -Scope $nsmScope -Level $level -Summary $summary -Details (ConvertTo-MtNsmTable -InputObject $rows -Property Gjennomgang, Status, Gjester, Gjentas)
}
