Administratorer er de mest attraktive målene for phishing. NSMs varsel (V1) ber om phishing-resistent autentisering. En registrert metode viser at administratorene kan bruke den, ikke at den kreves: kravet måles av MP.NSM.1001, og koblingen til V1 er derfor delvis. Sjekken teller administratorer som har registrert FIDO2, passkey, Windows Hello for Business eller Platform Credential for macOS. Certificate-based authentication (CBA) vises ikke i registreringsrapporten; er den på, sier resultatet det. Nødtilgangskontoer i `EmergencyAccessAccounts` og synkkontoer for Entra Connect holdes utenfor.

- **Høy grad:** alle administratorer.
- **Moderat grad:** minst 60 %.
- **Liten grad:** færre.

#### Remediation action

1. Gi administratorene FIDO2-nøkler eller passkeys i Microsoft Authenticator.
2. Bruk en registration campaign eller Temporary Access Pass for å få dem registrert.
3. Legg nødtilgangskontoene i `EmergencyAccessAccounts` i maester-config.json.

#### Lenker

- [NSM-varselet, tiltak V1: Bruk phishing-resistent multifaktorautentisering](https://nsm.no/aktuelt/nsm-hever-det-nasjonale-cyberrisikonivaet-til-hoyt). Delvis kobling: En registrert metode viser at administratorene kan bruke phishing-resistent MFA, ikke at den kreves. Kravet måles av MP.NSM.1001.
- [Authentication methods activity](https://learn.microsoft.com/entra/identity/authentication/howto-authentication-methods-activity)

<!--- Results --->
%TestResult%
