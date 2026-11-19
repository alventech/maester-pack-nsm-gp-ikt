Samtykke til ondsinnede apper er en vanlig måte å få varig tilgang til e-post og filer på, uten passord. GP-IKT 2.6.4 ber om å minimere rettighetene til sluttbrukere. Retten til å gi en app tilgang til virksomhetens data er en slik rettighet. Koblingen er vår lesning og derfor delvis: NSM nevner ikke app consent. Sjekken måler ikke V5 i varselet (kartlegging av tjenester i leverandørkjeden): å begrense samtykke forebygger, men kartlegger ingenting.

- **Høy grad:** brukere kan ikke gi samtykke selv; forespørsler går til administrator.
- **Moderat grad:** bare apper fra verified publishers, med tillatelser Microsoft klassifiserer som lav risiko.
- **Liten grad:** brukere kan samtykke til alle apper.

#### Remediation action

1. Slå av user consent, eller begrens det til verified publishers og utvalgte tillatelser.
2. Slå på admin consent workflow, slik at brukere kan be om en app.

#### Lenker

- [NSM 2.6.4: Minimer rettigheter til sluttbrukere og spesialbrukere](https://nsm.no/regelverk-og-hjelp/rad-og-anbefalinger/beskytte-og-opprettholde/ha-kontroll-pa-identiteter-og-tilganger/#:~:text=Minimer%20rettigheter%20til%20sluttbrukere%20og) (2.6 Ha kontroll på identiteter og tilganger). Delvis kobling: 2.6.4 ber om å minimere rettighetene til sluttbrukere. Retten til å gi en app tilgang til virksomhetens data er en slik rettighet. NSM nevner ikke app consent; dette er forfatterens lesning.
- [Configure how users consent to applications](https://learn.microsoft.com/entra/identity/enterprise-apps/configure-user-consent)

<!--- Results --->
%TestResult%
