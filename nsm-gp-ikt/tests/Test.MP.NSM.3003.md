GP-IKT 2.3.2 er et prioritet 1-tiltak: konfigurer klientene slik at bare kjent programvare kjører. På Windows gjøres dette med App Control for Business (tidligere WDAC) eller AppLocker. Koblingen er delvis: en tildelt policy viser at allowlisting er satt opp, ikke at den håndheves på hver enhet.

- **Høy grad:** App Control for Business er tildelt, som policy i Endpoint security eller som custom-profil med OMA-URI (`ApplicationControl`).
- **Moderat grad:** bare AppLocker via custom-profil med OMA-URI.
- **Liten grad:** ingen applikasjonskontroll.

Sjekken ser ikke om policyen håndheves eller står i audit-modus. Det må attesteres eller leses fra hendelsene i Defender.

#### Remediation action

1. Start med App Control for Business i audit-modus med Intune som managed installer.
2. Gå gjennom hendelsene i Defender, og slå over til håndheving.

#### Lenker

- [NSM 2.3.2: Konfigurer klienter slik at kun kjent programvare kjører på dem](https://nsm.no/regelverk-og-hjelp/rad-og-anbefalinger/beskytte-og-opprettholde/ivareta-en-sikker-konfigurasjon/#:~:text=Konfigurer%20klienter%20slik%20at%20kun) (2.3 Ivareta en sikker konfigurasjon). Delvis kobling til a): 2.3.2 a) og b) ber om allowlisting av programmer på klienter. En tildelt policy viser at allowlisting er satt opp, ikke at den håndheves på hver enhet.
- [App Control for Business with Intune](https://learn.microsoft.com/intune/intune-service/protect/endpoint-security-app-control-policy)

<!--- Results --->
%TestResult%
