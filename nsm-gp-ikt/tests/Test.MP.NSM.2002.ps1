function Test-MtNsmSecureScore {
    <#
    .SYNOPSIS
    Checks the Secure Score recommendations that turn off unnecessary and insecure functionality.

    .DESCRIPTION
    Reads the tenant's latest Microsoft Secure Score and looks only at the recommendations in the list below, each
    of which turns off a legacy protocol or a feature most organisations do not need. Microsoft lists only the
    recommendations that apply to the tenant: the device ones need devices in Defender for Endpoint, the on-premises
    ones need Defender for Identity.

    Høy grad: every listed recommendation the tenant has is fully met. Moderat grad: at least half are fully met.
    Liten grad: fewer. The overall Secure Score is shown for information and does not affect the level.
    #>
    [MaesterTest(
        Id = 'MP.NSM.2002',
        Title = 'Unødvendig og usikker funksjonalitet er slått av (Secure Score-anbefalinger)',
        Product = 'microsoft-365',
        Feature = 'organization-settings',
        Area = 'infrastructure',
        ResourceType = 'Tenant',
        Severity = 'Medium',
        UserImpact = 'Low',
        ImplementationCost = 'Medium',
        Control = ('nsm-gp-ikt:2.3.3'),
        Service = 'Graph',
        Permission = 'Graph:Scope:SecurityEvents.Read.All',
        Tag = ('NSM', 'NSM-M365'),
        Author = 'alventech'
    )]
    [CmdletBinding()]
    [OutputType([bool])]
    param()

    $nsmScope = 'Exchange Online, SharePoint og Teams, Windows-klienter i Defender for Endpoint og lokal AD i Defender for Identity'

    # Secure Score control name, and the functionality it turns off. Recommendations another test already scores are
    # left out: BlockLegacyAuthentication (MP.NSM.2001), IntegratedApps, user consent to apps (MP.NSM.1009), and
    # exo_outlookaddins (MP.NSM.2005, GP-IKT 2.8.4). Mail forwarding is not on the list: it is a data flow, not
    # unneeded functionality. scid_* come from Defender for Endpoint and AATP_* from Defender for Identity, so a
    # tenant without those products has fewer of the recommendations; the result says how many were assessed.
    $recommendations = [ordered]@{
        exo_oauth2clientprofileenabled      = 'Legacy authentication i Exchange Online'
        spo_legacy_auth                     = 'Legacy authentication i SharePoint Online'
        exo_storageproviderrestricted       = 'Eksterne lagringstjenester i Outlook on the web'
        aad_third_party_apps                = 'Brukere registrerer tredjepartsapper'
        admincenter_owned_apps_and_services = 'User owned apps and services'
        aad_linkedin_connection_disables    = 'LinkedIn account connections'
        meeting_anonymousstartmeeting_v1    = 'Anonyme brukere starter Teams-møter'
        scid_53                             = 'SMBv1-klient på Windows'
        scid_54                             = 'SMBv1-server på Windows'
        scid_30                             = 'Insecure guest logons i SMB'
        scid_73                             = 'Basic-autentisering for WinRM-klient'
        scid_74                             = 'Basic-autentisering for WinRM-tjeneste'
        scid_57                             = 'WDigest-autentisering'
        scid_72                             = 'LM- og NTLMv1-autentisering'
        scid_65                             = 'Lagring av LAN Manager-hash'
        scid_10000                          = 'Telnet'
        scid_10002                          = 'SNMP v1 og v2'
        scid_108                            = 'Remote Registry-tjenesten'
        scid_69                             = 'Autoplay på alle stasjoner'
        scid_70                             = 'AutoRun-kommandoer'
        scid_87                             = 'Solicited Remote Assistance'
        scid_63                             = 'Offer Remote Assistance'
        scid_80                             = 'Flash i Office-dokumenter'
        AATP_PrintSpooler                   = 'Print Spooler på domenekontrollere'
        AATP_ClearText                      = 'Clear text credentials (Active Directory)'
        AATP_WeakCipher                     = 'Weak cipher usage (Active Directory)'
    }

    try {
        $score = Get-MtNsmSecureScore
    } catch {
        # Usually SecurityEvents.Read.All, which Connect-Maester does not ask for.
        if (Test-MtNsmAccessDenied $_) { Add-MtTestResultDetail -SkippedBecause NotAuthorized; return $null }
        throw
    }
    if (-not $score) {
        Add-MtTestResultDetail -SkippedBecause Custom -SkippedCustomReason 'Secure Score er ikke tilgjengelig for tenanten.'
        return $null
    }

    $rows = foreach ($control in $score.controlScores | Where-Object { $recommendations.Contains([string]$_.controlName) }) {
        $met = [double]$control.scoreInPercentage
        # Microsoft's status is sometimes HTML.
        $status = ([string]$control.implementationStatus -replace '<[^>]+>', ' ' -replace '&nbsp;', ' ' -replace '\s+', ' ').Trim()
        [pscustomobject]@{
            Kilde      = if ($control.controlName -like 'scid_*') { 'Defender for Endpoint' } elseif ($control.controlName -like 'AATP_*') { 'Defender for Identity' } else { 'Microsoft 365' }
            'Slås av'  = $recommendations[[string]$control.controlName]
            Oppfylt    = if ($met -ge 100) { 'Ja' } elseif ($met -gt 0) { "Delvis ($([math]::Floor($met)) %)" } else { 'Nei' }
            Bevis      = $status
            Anbefaling = $control.controlName
            Full       = $met -ge 100
        }
    }
    $rows = @($rows | Sort-Object Full, 'Slås av')
    if ($rows.Count -eq 0) {
        Add-MtTestResultDetail -SkippedBecause Custom -SkippedCustomReason 'Secure Score har ingen av anbefalingene testen ser på for denne tenanten.'
        return $null
    }

    $full = @($rows | Where-Object Full).Count
    $level = if ($full -eq $rows.Count) { 'H' } elseif ($full * 2 -ge $rows.Count) { 'M' } else { 'L' }
    $overall = if ($score.maxScore) { " Samlet Secure Score er $(Format-MtNsmPercent ($score.currentScore / $score.maxScore)), til orientering." } else { '' }
    Complete-MtNsmResult -Scope $nsmScope -Level $level `
        -Summary "$full av $($rows.Count) anbefalinger fra Secure Score for å slå av unødvendig funksjonalitet er oppfylt. Tenanten har $($rows.Count) av de $($recommendations.Count) anbefalingene sjekken ser etter; resten finnes ikke uten Defender for Endpoint eller Defender for Identity.$overall" `
        -Details (ConvertTo-MtNsmTable -InputObject $rows -Property Kilde, 'Slås av', Oppfylt, Bevis, Anbefaling -Code Anbefaling)
}
