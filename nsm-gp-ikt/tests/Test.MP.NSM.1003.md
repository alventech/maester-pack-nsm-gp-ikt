Andelen brukere med phishing-resistent metode er et av nøkkeltallene for NSM-varselet (V1). En registrert metode viser at brukerne kan bruke den, ikke at den kreves: koblingen til V1 er derfor delvis. Sjekken teller aktive medlemsbrukere med lisens som har FIDO2, passkey, Windows Hello for Business eller Platform Credential for macOS. Gjester, synkkontoer, deaktiverte kontoer og kontoer uten lisens (som delte postbokser og møterom) holdes utenfor. Certificate-based authentication (CBA) vises ikke i registreringsrapporten; er den på, sier resultatet det.

- **Høy grad:** minst 95 %.
- **Moderat grad:** minst 50 %.
- **Liten grad:** færre.

#### Remediation action

1. Aktiver passkeys (FIDO2) i Authentication methods-policyen.
2. Rull ut Windows Hello for Business via Intune.
3. Kjør en registration campaign for passkeys i Microsoft Authenticator.

#### Lenker

- [NSM-varselet, tiltak V1: Bruk phishing-resistent multifaktorautentisering](https://nsm.no/aktuelt/nsm-hever-det-nasjonale-cyberrisikonivaet-til-hoyt). Delvis kobling: En registrert metode viser at brukerne kan bruke phishing-resistent MFA, ikke at den kreves. Kravet måles av MP.NSM.1001.
- [Passkeys in Microsoft Entra ID](https://learn.microsoft.com/entra/identity/authentication/how-to-enable-passkey-fido2)

<!--- Results --->
%TestResult%
