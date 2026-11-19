Angrep mot lokal Active Directory (passordspraying, Kerberoasting, DCSync) er vanskelige å oppdage uten sensor på domenekontrollerne. Sensoren gjør domenekontrollerne til en overvåket del av IKT-systemet (GP-IKT 3.2.3) og samler inn pålogginger og administrasjonshendelser derfra (3.2.4). Koblingen er delvis: begge tiltakene er beslutninger for hele IKT-systemet, og sensoren viser at de er gjennomført for domenekontrollerne.

- **Høy grad:** sensoren er installert.
- **Liten grad:** Secure Score melder at den mangler.

Krever Defender for Identity. Hoppes over som ikke relevant når tenanten ikke synkroniserer fra lokal AD, og når Secure Score ikke har kontrollen.

#### Remediation action

Installer Defender for Identity-sensoren på alle domenekontrollere, AD FS- og AD CS-servere og Entra Connect-servere.

#### Lenker

- [NSM 3.2.3: Avgjør hvilke deler av IKT-systemet som skal overvåkes](https://nsm.no/regelverk-og-hjelp/rad-og-anbefalinger/oppdage/etabler-sikkerhetsovervakning/#:~:text=Avgj%C3%B8r%20hvilke%20deler%20av%20IKT%2Dsystemet) (3.2 Etabler sikkerhetsovervåkning). Delvis kobling til a): 3.2.3 er en beslutning om hvilke deler av IKT-systemet som skal overvåkes. En sensor viser at beslutningen er gjennomført for domenekontrollerne, ikke at den er tatt for resten.
- [NSM 3.2.4: Beslutt hvilke data som er sikkerhetsrelevant og bør samles inn](https://nsm.no/regelverk-og-hjelp/rad-og-anbefalinger/oppdage/etabler-sikkerhetsovervakning/#:~:text=Beslutt%20hvilke%20data%20som%20er) (3.2 Etabler sikkerhetsovervåkning). Delvis kobling til a): Sensoren samler inn pålogginger og katalogendringer fra domenekontrollerne, en del av dataene 3.2.4 ber om.
- [Deploy Microsoft Defender for Identity](https://learn.microsoft.com/defender-for-identity/deploy/deploy-defender-identity)

<!--- Results --->
%TestResult%
