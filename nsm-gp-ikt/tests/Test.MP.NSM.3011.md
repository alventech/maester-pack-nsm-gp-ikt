GP-IKT 2.3.5 ber om å verifisere at aktivert sikkerhetskonfigurasjon er i henhold til den godkjente, automatisk og regelmessig. Intune gjør denne sammenligningen mot compliance policies hver gang en enhet synkroniserer. Sjekken teller Windows-enhetene Intune melder som compliant.

- **Høy grad:** minst 95 % er compliant.
- **Moderat grad:** minst 80 %.
- **Liten grad:** lavere.

Co-managed enheter der Configuration Manager vurderer compliance, holdes utenfor. Regner tenanten enheter uten compliance policy som compliant, blir resultatet høyst moderat grad, fordi andelen da sier mindre. Hva som blir verifisert, avhenger av hva compliance policies krever: koblingen til NSM er derfor delvis. Enheter som avviker, er listet i resultatet.

#### Remediation action

1. Krev BitLocker, Defender, brannmur og minimum OS-versjon i compliance policyen.
2. Sett **Mark devices with no compliance policy assigned as** til *Not compliant* under **Devices > Compliance > Compliance settings**.
3. Bruk Conditional Access som krever en compliant enhet, slik at avvik får en konsekvens.

#### Lenker

- [NSM 2.3.5: Verifiser at aktivert sikkerhetskonfigurasjon er i henhold til virksomhetens godkjente sikkerhetskonfigurasjon](https://nsm.no/regelverk-og-hjelp/rad-og-anbefalinger/beskytte-og-opprettholde/ivareta-en-sikker-konfigurasjon/#:~:text=Verifiser%20at%20aktivert%20sikkerhetskonfigurasjon%20er) (2.3 Ivareta en sikker konfigurasjon). Delvis kobling til d): 2.3.5 ber om å sammenligne aktivert konfigurasjon med den godkjente, automatisk og regelmessig (a, d). Intune gjør det mot compliance policies. Hva som blir sammenlignet, avhenger av hva policyene krever.
- [Device compliance policies in Intune](https://learn.microsoft.com/intune/intune-service/protect/device-compliance-get-started)

<!--- Results --->
%TestResult%
