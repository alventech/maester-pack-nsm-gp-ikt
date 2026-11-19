GP-IKT 2.3.3 ber virksomheten deaktivere unødvendig funksjonalitet. Microsoft Secure Score har egne anbefalinger for mye av dette, hver med Microsofts egen status for tenanten. Sjekken ser bare på de anbefalingene som slår av eldre protokoller eller funksjoner de fleste ikke trenger:

- **Legacy authentication i tjenestene:** Exchange Online og SharePoint Online.
- **E-post og apper:** eksterne lagringstjenester, tredjepartsapper, LinkedIn account connections, anonyme Teams-møter.
- **Windows-enheter (Defender for Endpoint):** SMBv1, insecure guest logons i SMB, Basic-autentisering for WinRM, WDigest, LM og NTLMv1, lagret LM-hash, Telnet, SNMP v1/v2, Remote Registry, Autoplay og AutoRun, Remote Assistance, Flash i Office.
- **Active Directory (Defender for Identity):** Print Spooler på domenekontrollere, clear text credentials, weak cipher usage.

Anbefalinger som andre tester i pakken allerede vurderer, er utelatt: blokkering av legacy authentication med Conditional Access (MP.NSM.2001), user consent til apper (MP.NSM.1009) og Outlook-tillegg (MP.NSM.2005, GP-IKT 2.8.4). Videresending av e-post er ikke med: det er en dataflyt, ikke unødvendig funksjonalitet.

Microsoft viser bare anbefalinger som gjelder tenanten. Enhetsanbefalingene krever enheter i Defender for Endpoint, og AD-anbefalingene krever Defender for Identity. Resultatet viser Microsofts bevis for hver anbefaling: hvor mange enheter eller brukere som er berørt, og om innstillingen er satt.

Resultatet sier hvor mange av anbefalingene tenanten har. Få anbefalinger betyr at vurderingen hviler på et smalere grunnlag, ikke at resten er i orden.

- **Høy grad:** alle anbefalingene tenanten har, er fullt oppfylt.
- **Moderat grad:** minst halvparten er fullt oppfylt.
- **Liten grad:** færre.

Den samlede Secure Score vises til orientering. Den påvirker ikke vurderingen, fordi prosenten blander hundrevis av anbefalinger som ikke hører til tiltaket.

#### Remediation action

Åpne hver anbefaling som ikke er oppfylt i Microsoft Defender-portalen under **Exposure management > Secure Score > Recommended actions** (søk på navnet i kolonnen *Anbefaling*), og følg Microsofts fremgangsmåte. Godtar dere en anbefaling som risiko, merk den som *Risk accepted* i portalen og dokumenter hvorfor.

#### Lenker

- [NSM 2.3.3: Deaktiver unødvendig funksjonalitet](https://nsm.no/regelverk-og-hjelp/rad-og-anbefalinger/beskytte-og-opprettholde/ivareta-en-sikker-konfigurasjon/#:~:text=Deaktiver%20un%C3%B8dvendig%20funksjonalitet) (2.3 Ivareta en sikker konfigurasjon). Delvis kobling: 2.3.3 ber om å slå av innebygd funksjonalitet som ikke trengs, som eldre protokoller. Forfatteren har valgt anbefalingene; hvilke som finnes i tenanten, avhenger av lisensene, og resultatet sier hvor mange som ble vurdert.
- [Microsoft Secure Score](https://learn.microsoft.com/defender-xdr/microsoft-secure-score)
- [Assess your security posture with Secure Score](https://learn.microsoft.com/defender-xdr/microsoft-secure-score-improvement-actions)

<!--- Results --->
%TestResult%
