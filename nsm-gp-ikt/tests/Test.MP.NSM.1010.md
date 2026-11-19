Entra lager anbefalinger når konfigurasjonen avviker fra Microsofts beste praksis, for eksempel manglende MFA for administratorer eller legacy authentication som ikke er blokkert. Dette er en indikator, ikke en måling av et NSM-tiltak: listen blander ulike anbefalinger og telles etter antall. Den viser retning, flere av anbefalingene gjelder MFA (GP-IKT 2.6.7), men sjekken har ingen `Control` og teller ikke som dekning.

- **Høy grad:** ingen aktive anbefalinger med høy prioritet.
- **Moderat grad:** én eller to.
- **Liten grad:** flere.

#### Remediation action

Gå gjennom anbefalingene i Entra admin center under **Identity > Overview > Recommendations**, og lukk dem med høy prioritet først.

#### Lenker

- [NSM 2.6.7: Bruk multi-faktor autentisering](https://nsm.no/regelverk-og-hjelp/rad-og-anbefalinger/beskytte-og-opprettholde/ha-kontroll-pa-identiteter-og-tilganger/#:~:text=Bruk%20multi%2Dfaktor%20autentisering) (2.6 Ha kontroll på identiteter og tilganger). Indikator, teller ikke som dekning: En blandet liste telt etter antall. Den viser retning, og flere av anbefalingene gjelder MFA, men den beviser ikke noe enkelt tiltak.
- [Microsoft Entra recommendations](https://learn.microsoft.com/entra/identity/monitoring-health/overview-recommendations)

<!--- Results --->
%TestResult%
