GP-IKT 2.6.5 b) ber om å begrense bruken av kontoer med fulle rettigheter til et minimum. NSM nevner ikke tidsbegrensning; at få permanente tildelinger oppfyller dette i Entra ID, er vår lesning, og koblingen er delvis. Permanente tildelinger av privilegerte roller gir en angriper som tar over kontoen full tilgang uten videre steg. Sjekken teller kontoer med aktive privilegerte roller uten sluttdato, utenom nødtilgangskontoene i `EmergencyAccessAccounts`.

- **Høy grad:** høyst to.
- **Moderat grad:** tre til fem.
- **Liten grad:** flere.

Uten Entra ID P2 finnes ikke PIM, og alle aktive tildelinger regnes som permanente. Mangler tilkoblingen tillatelse, hoppes sjekken over. En gruppe med en rolle telles som én konto; om medlemskapet i gruppen styres av PIM for grupper, ser ikke sjekken.

#### Remediation action

1. Gjør privilegerte roller eligible i Privileged Identity Management i stedet for permanente.
2. Behold bare to nødtilgangskontoer med permanent Global Administrator, og legg dem i `EmergencyAccessAccounts`.

#### Lenker

- [NSM 2.6.5: Minimer rettigheter på drifts-kontoer](https://nsm.no/regelverk-og-hjelp/rad-og-anbefalinger/beskytte-og-opprettholde/ha-kontroll-pa-identiteter-og-tilganger/#:~:text=Minimer%20rettigheter%20p%C3%A5%20drifts%2Dkontoer) (2.6 Ha kontroll på identiteter og tilganger). Delvis kobling til b): 2.6.5 b) ber om å begrense bruken av kontoer med fulle rettigheter til et minimum. Få permanente tildelinger er forfatterens lesning av det for Entra ID; NSM nevner ikke tidsbegrensning.
- [Plan a Privileged Identity Management deployment](https://learn.microsoft.com/entra/id-governance/privileged-identity-management/pim-deployment-plan)

<!--- Results --->
%TestResult%
