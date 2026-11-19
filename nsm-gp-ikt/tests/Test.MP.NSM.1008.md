GP-IKT 2.6.1 e) sier at kontoer, tilganger og rettigheter bør revideres jevnlig. Sjekken måler ikke 2.6.3 (utløpsdato for innleide kontoer, ubrukte kontoer og passordkvalitet), og ikke gjennomgang av driftskontoer, som NSM kaller spesielt kritisk. Leverandører har ofte gjestekontoer eller medlemskap i grupper som ingen følger opp. Sjekken ser etter access reviews i Entra ID Governance.

- **Høy grad:** en gjentakende gjennomgang dekker gjester.
- **Moderat grad:** gjennomganger finnes, men ingen gjentakende av gjester.
- **Liten grad:** ingen.

Krever Entra ID P2 eller ID Governance. En tenant uten gjestebrukere har ingenting å gjennomgå, og sjekken hoppes over som ikke relevant.

#### Remediation action

1. Lag en kvartalsvis access review av alle gjester i Microsoft 365-grupper og Teams.
2. La eieren av hver leverandøravtale være godkjenner, og fjern tilgangen automatisk når den ikke bekreftes.

#### Lenker

- [NSM 2.6.1: Etabler retningslinjer for tilgangskontroll](https://nsm.no/regelverk-og-hjelp/rad-og-anbefalinger/beskytte-og-opprettholde/ha-kontroll-pa-identiteter-og-tilganger/#:~:text=Etabler%20retningslinjer%20for%20tilgangskontroll) (2.6 Ha kontroll på identiteter og tilganger). Direkte kobling til e): 2.6.1 e) sier at kontoer, tilganger og rettigheter bør revideres jevnlig. En gjentakende access review er den revisjonen, her for gjester. Driftskontoer, som NSM kaller spesielt kritiske, måles ikke.
- [Review guest access with access reviews](https://learn.microsoft.com/entra/id-governance/manage-guest-access-with-access-reviews)

<!--- Results --->
%TestResult%
