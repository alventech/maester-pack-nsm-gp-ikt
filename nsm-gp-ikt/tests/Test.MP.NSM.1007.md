Med Privileged Identity Management har administratorer rollen bare når de trenger den, og aktiveringen kan kreve godkjenning og MFA. GP-IKT 2.6.1 d) sier at tilganger og rettigheter bør spores til en ansvarlig rolle og person som godkjente dem: godkjenning og begrunnelse ved aktivering er den sporingen. Det støtter også 2.6.5 b) om å begrense bruken av kontoer med fulle rettigheter.

- **Høy grad:** privilegerte roller er eligible, og aktivering av Global Administrator krever godkjenning og MFA eller en authentication context.
- **Moderat grad:** eligible-tildelinger finnes, men aktiveringen krever ikke godkjenning, eller verken MFA eller authentication context.
- **Liten grad:** PIM brukes ikke for privilegerte roller.

Krever Entra ID P2 eller ID Governance, og tillatelsen `RoleManagementPolicy.Read.Directory` for å lese aktiveringsreglene. Uten tillatelsen hoppes sjekken over.

#### Remediation action

1. Gjør privilegerte roller eligible i PIM.
2. Krev godkjenning, MFA (helst authentication context med phishing-resistent authentication strength) og begrunnelse ved aktivering av Global Administrator og andre tier 0-roller.

#### Lenker

- [NSM 2.6.1: Etabler retningslinjer for tilgangskontroll](https://nsm.no/regelverk-og-hjelp/rad-og-anbefalinger/beskytte-og-opprettholde/ha-kontroll-pa-identiteter-og-tilganger/#:~:text=Etabler%20retningslinjer%20for%20tilgangskontroll) (2.6 Ha kontroll på identiteter og tilganger). Direkte kobling til d): 2.6.1 d) sier at tilganger og rettigheter bør spores til en ansvarlig rolle og person som godkjente dem. Godkjenning og begrunnelse ved aktivering i PIM er den sporingen.
- [NSM 2.6.5: Minimer rettigheter på drifts-kontoer](https://nsm.no/regelverk-og-hjelp/rad-og-anbefalinger/beskytte-og-opprettholde/ha-kontroll-pa-identiteter-og-tilganger/#:~:text=Minimer%20rettigheter%20p%C3%A5%20drifts%2Dkontoer) (2.6 Ha kontroll på identiteter og tilganger). Delvis kobling til b): Roller som må aktiveres, begrenser bruken av kontoer med fulle rettigheter, som 2.6.5 b) ber om.
- [Configure Microsoft Entra role settings in PIM](https://learn.microsoft.com/entra/id-governance/privileged-identity-management/pim-how-to-change-default-settings)

<!--- Results --->
%TestResult%
