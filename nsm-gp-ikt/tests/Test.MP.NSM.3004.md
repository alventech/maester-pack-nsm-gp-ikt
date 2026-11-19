Attack surface reduction-regler (ASR) i Microsoft Defender stopper kjente angrepsmønstre på klienten, som at Office starter andre programmer eller at innhold fra e-post kjører. Det svarer til GP-IKT 3.1.3 b) (IDS/IPS-funksjonalitet på klienter) og begrenser programkode som følger med dokumenter, som 2.3.2 d) ber om. Sjekken ser etter tildelte ASR-policyer i Intune.

- **Høy grad:** tildelt alle enheter eller alle brukere.
- **Moderat grad:** tildelt bare til grupper.
- **Liten grad:** ikke tildelt.

Både nye policyer og eldre policyer (intents) teller. En tildeling bare til ekskluderte grupper teller ikke. En tildelt policy viser at innstillingen styres sentralt, ikke at den er i kraft på hver enhet: koblingen til NSM er derfor delvis, og vurderingen gjelder Windows-klienter i Intune. Sjekken ser ikke om reglene står i block-modus eller audit-modus.

#### Remediation action

1. Lag en policy under **Endpoint security > Attack surface reduction** med regelsettet Microsoft anbefaler.
2. Kjør reglene i audit-modus først, se på hendelsene i Defender, og sett dem deretter i block-modus.
3. Tildel policyen alle Windows-enheter.

#### Lenker

- [NSM 3.1.3: Benytt automatisert og sentralisert verktøy for å håndtere kjente trusler (som skadevare)](https://nsm.no/regelverk-og-hjelp/rad-og-anbefalinger/oppdage/oppdag-og-fjern-kjente-sarbarheter-og-trusler/#:~:text=Benytt%20automatisert%20og%20sentralisert%20verkt%C3%B8y) (3.1 Oppdag og fjern kjente sårbarheter og trusler). Delvis kobling til b): 3.1.3 b) ber om IDS/IPS-funksjonalitet på klienter. ASR-regler stopper kjente angrepsmønstre på klienten. En tildelt policy viser at reglene styres sentralt, ikke at de står i block-modus på hver enhet.
- [NSM 2.3.2: Konfigurer klienter slik at kun kjent programvare kjører på dem](https://nsm.no/regelverk-og-hjelp/rad-og-anbefalinger/beskytte-og-opprettholde/ivareta-en-sikker-konfigurasjon/#:~:text=Konfigurer%20klienter%20slik%20at%20kun) (2.3 Ivareta en sikker konfigurasjon). Delvis kobling til d): 2.3.2 d) gjelder programkode som følger med dokumenter, som makroer. Flere ASR-regler begrenser hva Office-makroer og -dokumenter kan starte.
- [Attack surface reduction rules](https://learn.microsoft.com/defender-endpoint/attack-surface-reduction)

<!--- Results --->
%TestResult%
