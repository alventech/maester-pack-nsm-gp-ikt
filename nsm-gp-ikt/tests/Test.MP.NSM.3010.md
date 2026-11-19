GP-IKT 2.3.4 ber om en standard sikkerhetskonfigurasjon per type enhet, driftet sentralt. Sjekken ser etter en tildelt security baseline for Windows: Microsofts security baseline i Intune, eller en policy i Settings catalog med et navn som passer mønsteret i innstillingen `NsmGpIkt.BaselinePolicyPattern` (standard: CIS eller baseline).

- **Høy grad:** tildelt alle enheter eller alle brukere.
- **Moderat grad:** tildelt bare til grupper.
- **Liten grad:** ikke tildelt.

Både nye policyer og eldre policyer (intents) teller. En tildeling bare til ekskluderte grupper teller ikke. En tildelt policy viser at innstillingen styres sentralt, ikke at den er i kraft på hver enhet: koblingen til NSM er derfor delvis, og vurderingen gjelder Windows-klienter i Intune. Sjekken ser ikke om baselinen blir gjennomgått jevnlig, eller hvordan endringer i den godkjennes (2.3.4 b og c).

#### Remediation action

1. Ta i bruk Intunes security baseline for Windows, eller CIS Level 1 fra Settings catalog.
2. Tildel baselinen alle Windows-enheter, og sett en eier som går gjennom den når Microsoft eller CIS gir ut en ny versjon.

#### Lenker

- [NSM 2.3.4: Etabler og vedlikehold standard sikkerhetskonfigurasjoner](https://nsm.no/regelverk-og-hjelp/rad-og-anbefalinger/beskytte-og-opprettholde/ivareta-en-sikker-konfigurasjon/#:~:text=Etabler%20og%20vedlikehold%20standard%20sikkerhetskonfigurasjoner) (2.3 Ivareta en sikker konfigurasjon). Delvis kobling til a): 2.3.4 ber om en standard sikkerhetskonfigurasjon per type enhet, sentralisert (a). En tildelt security baseline er den standarden for Windows-klienter. Gjennomgang og endringshåndtering (b, c) måles ikke.
- [Security baselines in Intune](https://learn.microsoft.com/intune/intune-service/protect/security-baselines)

<!--- Results --->
%TestResult%
