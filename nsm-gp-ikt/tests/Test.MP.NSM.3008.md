GP-IKT 2.4.4 sier: aktiver brannmur på alle klienter og servere. Sjekken ser etter en tildelt brannmurpolicy for Windows i Intune. Policyer som bare inneholder brannmurregler, teller ikke.

- **Høy grad:** tildelt alle enheter eller alle brukere.
- **Moderat grad:** tildelt bare til grupper.
- **Liten grad:** ikke tildelt.

Både nye policyer og eldre policyer (intents) teller. En tildeling bare til ekskluderte grupper teller ikke. En tildelt policy viser at innstillingen styres sentralt, ikke at den er i kraft på hver enhet: koblingen til NSM er derfor delvis, og vurderingen gjelder Windows-klienter i Intune. Servere måles ikke.

#### Remediation action

1. Lag en policy under **Endpoint security > Firewall** som slår på brannmuren for alle tre profiler (domene, privat og offentlig).
2. Tildel policyen alle Windows-enheter.

#### Lenker

- [NSM 2.4.4: Aktiver brannmur på alle klienter og servere](https://nsm.no/regelverk-og-hjelp/rad-og-anbefalinger/beskytte-og-opprettholde/beskytt-virksomhetens-nettverk/#:~:text=Aktiver%20brannmur%20p%C3%A5%20alle%20klienter) (2.4 Beskytt virksomhetens nettverk). Delvis kobling til a): 2.4.4 sier: aktiver brannmur på alle klienter og servere. En tildelt brannmurpolicy viser at brannmuren styres sentralt på Windows-klientene, ikke at den er på hver enhet. Servere måles ikke.
- [Firewall policy for endpoint security in Intune](https://learn.microsoft.com/intune/intune-service/protect/endpoint-security-firewall-policy)

<!--- Results --->
%TestResult%
