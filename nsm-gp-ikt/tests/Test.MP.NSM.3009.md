GP-IKT 3.1.3 a) ber om antivirus, fortrinnsvis en sentralt styrt løsning. Sjekken ser etter en tildelt policy for Microsoft Defender Antivirus i Intune. Policyer som bare inneholder unntak eller innstillinger for Windows Security-appen, teller ikke.

- **Høy grad:** tildelt alle enheter eller alle brukere.
- **Moderat grad:** tildelt bare til grupper.
- **Liten grad:** ikke tildelt.

Både nye policyer og eldre policyer (intents) teller. En tildeling bare til ekskluderte grupper teller ikke. En tildelt policy viser at innstillingen styres sentralt, ikke at den er i kraft på hver enhet: koblingen til NSM er derfor delvis, og vurderingen gjelder Windows-klienter i Intune.

#### Remediation action

1. Lag en policy under **Endpoint security > Antivirus** for Microsoft Defender Antivirus, med sanntidsbeskyttelse og skybeskyttelse på.
2. Tildel policyen alle Windows-enheter.

#### Lenker

- [NSM 3.1.3: Benytt automatisert og sentralisert verktøy for å håndtere kjente trusler (som skadevare)](https://nsm.no/regelverk-og-hjelp/rad-og-anbefalinger/oppdage/oppdag-og-fjern-kjente-sarbarheter-og-trusler/#:~:text=Benytt%20automatisert%20og%20sentralisert%20verkt%C3%B8y) (3.1 Oppdag og fjern kjente sårbarheter og trusler). Delvis kobling til a): 3.1.3 a) ber om antivirus, fortrinnsvis sentralt styrt. En tildelt antiviruspolicy viser at løsningen styres sentralt, ikke at den er aktiv og oppdatert på hver enhet.
- [Antivirus policy for endpoint security in Intune](https://learn.microsoft.com/intune/intune-service/protect/endpoint-security-antivirus-policy)

<!--- Results --->
%TestResult%
