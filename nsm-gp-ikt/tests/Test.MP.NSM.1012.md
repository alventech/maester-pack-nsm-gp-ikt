GP-IKT 2.2.6 ber om å regulere tilgang til tjenester ut fra kjennskap til både bruker og enhet: en bruker på en enhet virksomheten ikke forvalter, bør få tilgang til færre tjenester. Sjekken ser etter Conditional Access-policyer som krever en compliant enhet eller en hybrid joined enhet.

- **Høy grad:** en aktivert policy krever en forvaltet enhet for alle brukere, for alle apper eller Office 365, med høyst to unntak og uten vilkår som begrenser den.
- **Moderat grad:** bare for noen brukere eller apper, med flere unntak eller begrensende vilkår (locations, device platforms, client apps, risk, filter for devices), eller bare i report-only.
- **Liten grad:** ingen slik policy.

«MFA **eller** compliant enhet» teller ikke som et krav om forvaltet enhet, fordi kravet kan oppfylles uten. Unntak utover nødtilgangskontoene i `EmergencyAccessAccounts` telles. Sjekken ser ikke andre måter å skille på enhet, som appbegrensninger i SharePoint og Exchange for ikke-forvaltede enheter, eller blokkering med filter for devices.

#### Remediation action

1. Lag en Conditional Access-policy som krever en compliant enhet for alle brukere, først i report-only.
2. Se på påloggingsloggen hvem som ville blitt stoppet, og få enhetene deres inn i Intune.
3. Aktiver policyen, med unntak bare for nødtilgangskontoene.

#### Lenker

- [NSM 2.2.6: Reguler tilgang til tjenester basert på kjennskap til både brukere og enhet](https://nsm.no/regelverk-og-hjelp/rad-og-anbefalinger/beskytte-og-opprettholde/etabler-en-sikker-ikt-arkitektur/#:~:text=Reguler%20tilgang%20til%20tjenester%20basert) (2.2 Etabler en sikker IKT-arkitektur). Direkte kobling: 2.2.6 ber om å regulere tilgang til tjenester ut fra kjennskap til både bruker og enhet. En Conditional Access-policy som krever en forvaltet enhet, er NSMs eget eksempel.
- [Require a compliant device with Conditional Access](https://learn.microsoft.com/entra/identity/conditional-access/policy-all-users-device-compliance)

<!--- Results --->
%TestResult%
