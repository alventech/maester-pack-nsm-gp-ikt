GP-IKT 2.6.4 a) sier: ikke tildel administrator-rettigheter til sluttbrukere. I Entra ID avgjør Device settings om brukeren som kobler en Windows-enhet til Entra ID, blir lokal administrator på den. Standardverdien er at alle blir det. Sjekken leser innstillingen.

- **Høy grad:** ingen blir lokal administrator ved tilkobling.
- **Moderat grad:** utvalgte brukere eller grupper blir det.
- **Liten grad:** alle brukere blir det.

Sjekken leser tenantens innstilling, ikke hvem som faktisk er lokal administrator på hver enhet. En Windows Autopilot-profil som setter brukerkontoen til standardbruker, og Intune-policyer for lokale grupper, kan gi et strengere resultat på enhetene enn innstillingen viser. Om Global Administrator-rollen er lokal administrator, vises i resultatet, men vurderes ikke.

#### Remediation action

1. Gå til **Entra ID > Devices > Device settings** og sett **Registering user is added as local administrator on the device during Microsoft Entra join** til *None*.
2. Sett brukerkontotypen til *Standard* i Windows Autopilot-profilene.
3. Gi midlertidige administratorrettigheter med Endpoint Privilege Management eller Windows LAPS der det trengs.

#### Lenker

- [NSM 2.6.4: Minimer rettigheter til sluttbrukere og spesialbrukere](https://nsm.no/regelverk-og-hjelp/rad-og-anbefalinger/beskytte-og-opprettholde/ha-kontroll-pa-identiteter-og-tilganger/#:~:text=Minimer%20rettigheter%20til%20sluttbrukere%20og) (2.6 Ha kontroll på identiteter og tilganger). Direkte kobling til a): 2.6.4 a) sier: ikke tildel administrator-rettigheter til sluttbrukere. Innstillingen avgjør om brukeren som kobler en enhet til Entra ID, blir lokal administrator på den.
- [Manage the local administrators group on Microsoft Entra joined devices](https://learn.microsoft.com/entra/identity/devices/assign-local-admin)

<!--- Results --->
%TestResult%
