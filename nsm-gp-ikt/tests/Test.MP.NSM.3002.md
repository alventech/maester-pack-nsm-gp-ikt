GP-IKT 2.3.1 ber om et sentralt styrt regime for sikkerhetsoppdateringer. Sjekken ser etter tildelte update rings (Windows Update for Business) og hvor mange Windows-enheter som har vært i kontakt med Intune den siste uken. En enhet som ikke synkroniserer, får heller ikke oppdateringer. Koblingen er delvis: sjekken viser at regimet finnes for Windows-klienter, ikke hvor raskt oppdateringene blir installert, og ikke applikasjoner, servere, skrivere eller nettverksutstyr, som 2.3.1 a) også nevner.

- **Høy grad:** tildelt ring, og minst 95 % har synkronisert de siste 7 dagene.
- **Moderat grad:** tildelt ring, og minst 70 %.
- **Liten grad:** ingen tildelt ring, eller færre enheter.

Enheter som ikke har synkronisert, er listet i resultatet. Windows Autopatch bruker også update rings og telles med.

#### Remediation action

1. Ta i bruk Windows Autopatch, eller lag update rings med frister på høyst 7 dager for quality updates.
2. Følg opp eller fjern enheter som ikke har synkronisert på lenge.

#### Lenker

- [NSM 2.3.1: Etabler et sentralt styrt regime for sikkerhetsoppdatering](https://nsm.no/regelverk-og-hjelp/rad-og-anbefalinger/beskytte-og-opprettholde/ivareta-en-sikker-konfigurasjon/#:~:text=Etabler%20et%20sentralt%20styrt%20regime) (2.3 Ivareta en sikker konfigurasjon). Delvis kobling til d): 2.3.1 ber om et sentralt styrt regime og automatisering (d). En tildelt update ring og enheter som synkroniserer med Intune, viser at regimet finnes for Windows-klienter. Sjekken måler ikke hvor raskt oppdateringene blir installert.
- [Windows Autopatch](https://learn.microsoft.com/windows/deployment/windows-autopatch/overview/windows-autopatch-overview)

<!--- Results --->
%TestResult%
