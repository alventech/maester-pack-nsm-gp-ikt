GP-IKT 2.6.7 ber om sterk autentisering for alle brukere. Sjekken ser etter en Conditional Access-policy som krever MFA (eller en authentication strength) for alle brukere og alle skyapper. Unntak utover nødtilgangskontoene i `EmergencyAccessAccounts` telles: ekskluderte brukere, grupper, roller, gjester og apper.

- **Høy grad:** aktivert, med høyst to unntak, uten vilkår som begrenser den (locations, device platforms, client apps, risk, filter for devices), og MFA kan ikke erstattes av en annen kontroll.
- **Moderat grad:** flere unntak, begrensende vilkår, «MFA **eller** compliant enhet», eller bare i report-only.
- **Liten grad:** ingen slik policy.

#### Remediation action

1. Lag eller juster policyen «Require multifactor authentication for all users» slik at den gjelder alle apper.
2. Fjern unntak som ikke er nødtilgangskontoer, og dokumenter de som må stå.

#### Lenker

- [NSM 2.6.7: Bruk multi-faktor autentisering](https://nsm.no/regelverk-og-hjelp/rad-og-anbefalinger/beskytte-og-opprettholde/ha-kontroll-pa-identiteter-og-tilganger/#:~:text=Bruk%20multi%2Dfaktor%20autentisering) (2.6 Ha kontroll på identiteter og tilganger). Direkte kobling til a): 2.6.7 a) ber om multi-faktor som et minimum for kontoer med tilgang til kritiske data og for brukere med driftsoppgaver. MFA for alle brukere og alle apper dekker begge.
- [Require MFA for all users](https://learn.microsoft.com/entra/identity/conditional-access/policy-all-users-mfa-strength)

<!--- Results --->
%TestResult%
