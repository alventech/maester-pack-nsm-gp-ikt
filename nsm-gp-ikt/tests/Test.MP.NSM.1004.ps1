function Test-MtNsmAuthenticationMethodPolicy {
    <#
    .SYNOPSIS
    Checks that FIDO2/passkeys are enabled and that SMS, voice calls and Email OTP are disabled.

    .DESCRIPTION
    Høy grad: FIDO2 enabled with attestation, SMS, voice and Email OTP disabled. Moderat grad: FIDO2 enabled, but
    SMS, voice or Email OTP still enabled, or no attestation. Liten grad: FIDO2 disabled. Email OTP here is the
    method for the tenant's own users (self-service password reset); Email OTP for guests is a separate setting
    (allowExternalIdToUseEmailOtp) and is not scored.
    #>
    [MaesterTest(
        Id = 'MP.NSM.1004',
        Title = 'Authentication methods-policyen tillater passkeys og slår av SMS, tale og Email OTP',
        Product = 'entra',
        Feature = 'authentication-methods',
        Area = 'authentication',
        ResourceType = 'Policy',
        Severity = 'Medium',
        UserImpact = 'Low',
        ImplementationCost = 'Low',
        Control = ('nsm-varsel-2026:V1'),
        Mitre = ('T1566.002', 'T1621', 'T1111'),
        Service = 'Graph',
        Permission = 'Graph:Scope:Policy.Read.All',
        Tag = ('NSM', 'NSM-Identitet'),
        Author = 'alventech'
    )]
    [CmdletBinding()]
    [OutputType([bool])]
    param()

    $nsmScope = 'Entra ID-tenanten'

    $policy = Invoke-MtGraphRequest -RelativeUri 'policies/authenticationMethodsPolicy' -ApiVersion v1.0
    $methods = @{}
    foreach ($c in $policy.authenticationMethodConfigurations) { $methods[$c.id] = $c }

    $fido = $methods['Fido2']
    $fidoOn = $fido -and $fido.state -eq 'enabled'
    $attested = $fidoOn -and $fido.isAttestationEnforced
    # Weak methods by their names in the Entra portal. Email OTP lets the tenant's users reset their password
    # with a code sent by email; guests' Email OTP is a separate setting and is not scored.
    $weakNames = [ordered]@{ Sms = 'SMS'; Voice = 'Voice call'; Email = 'Email OTP' }
    $weak = @($weakNames.Keys | Where-Object { $methods[$_] -and $methods[$_].state -eq 'enabled' } | ForEach-Object { $weakNames[$_] })
    # Until the migration is complete, the legacy MFA and SSPR policies still apply and can allow SMS and voice.
    $legacy = $policy.policyMigrationState -in 'preMigration', 'migrationInProgress'

    $rows = foreach ($id in 'Fido2', 'MicrosoftAuthenticator', 'TemporaryAccessPass', 'Sms', 'Voice', 'SoftwareOath', 'Email', 'X509Certificate') {
        if ($methods[$id]) { [pscustomobject]@{ Metode = $id; Status = $methods[$id].state } }
    }
    if (-not $fidoOn) {
        $level = 'L'; $summary = 'FIDO2/passkeys er ikke aktivert.'
    } elseif ($weak -or -not $attested -or $legacy) {
        $level = 'M'
        $summary = "FIDO2 er aktivert$(if (-not $attested) { ' uten attestation' }).$(if ($weak) { " Fortsatt på: $($weak -join ', ')." })"
        if ($legacy) { $summary += " Migreringen fra legacy MFA- og SSPR-policyene er ikke fullført ($($policy.policyMigrationState)), så de kan fortsatt tillate SMS og tale." }
    } else {
        $level = 'H'; $summary = 'FIDO2 er aktivert med attestation, SMS, tale og Email OTP er av, og migreringen fra legacy-policyene er fullført.'
    }
    Complete-MtNsmResult -Scope $nsmScope -Level $level -Summary $summary -Details (ConvertTo-MtNsmTable -InputObject @($rows) -Property Metode, Status)
}
