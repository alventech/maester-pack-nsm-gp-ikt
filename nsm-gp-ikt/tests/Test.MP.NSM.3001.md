Felles passord på lokale administratorkontoer lar en angriper flytte seg fra én maskin til alle. Windows LAPS gir hver enhet et unikt, roterende passord. GP-IKT 2.3.7 ber om å endre alle standardpassord. Windows har ikke et standardpassord, men et felles lokalt administratorpassord virker som ett: at LAPS svarer på tiltaket, er vår lesning, og koblingen er delvis.

- **Høy grad:** en LAPS-policy er tildelt alle enheter. Både policyen i Endpoint security og LAPS satt i Settings catalog teller; en tildeling bare til ekskluderte grupper teller ikke.
- **Moderat grad:** bare til grupper.
- **Liten grad:** ingen, eller LAPS er slått av i Device settings i Entra ID i en tenant uten lokal Active Directory. Policyene har da ingen steder å lagre passordet.

I en hybrid tenant kan passordet lagres i lokal Active Directory. Er LAPS slått av i Entra ID der, sier resultatet det uten å senke vurderingen.

Policyer for Local user group membership (Account protection) vises også i tabellen, men inngår ikke i vurderingen. Sjekken måler derfor ikke GP-IKT 2.6.4 (ingen administratorrettigheter for sluttbrukere); det gjør MP.NSM.1011.

#### Remediation action

1. Slå på **Enable Microsoft Entra Local Administrator Password Solution (LAPS)** under **Entra ID > Devices > Device settings**.
2. Lag en Windows LAPS-policy under **Endpoint security > Account protection** og tildel den alle Windows-enheter.
3. Fjern brukere fra den lokale administratorgruppen med policyen «Local user group membership».

#### Lenker

- [NSM 2.3.7: Endre alle standardpassord på IKT-produktene før produksjonssetting](https://nsm.no/regelverk-og-hjelp/rad-og-anbefalinger/beskytte-og-opprettholde/ivareta-en-sikker-konfigurasjon/#:~:text=Endre%20alle%20standardpassord%20p%C3%A5%20IKT%2Dproduktene) (2.3 Ivareta en sikker konfigurasjon). Delvis kobling: 2.3.7 ber om å endre alle standardpassord. Windows har ikke et standardpassord, men et felles passord på lokale administratorkontoer virker som ett. LAPS gir hver enhet sitt eget. Dette er forfatterens lesning.
- [Windows LAPS with Intune](https://learn.microsoft.com/intune/intune-service/protect/windows-laps-overview)

<!--- Results --->
%TestResult%
