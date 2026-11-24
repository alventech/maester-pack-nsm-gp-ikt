# How tests map to NSM

## Sources

| Source | Used for | Checked |
| --- | --- | --- |
| *Regneark med tiltak fra NSMs grunnprinsipper for IKT-sikkerhet* (NSM's spreadsheet, tab "01 NSM GP-IKT 2.1", last changed 2026-04) | Measure IDs, principle, priority, NSM's mapping to ISO/IEC 27002:2022 | `tools/extract_gp.py` reads it; all 118 measures match field by field |
| The 21 principle pages on nsm.no | The link to each measure | Every measure ID and title found on its page, 2026-11-09 |
| [NSM hever det nasjonale cyberrisikonivået til HØYT](https://nsm.no/aktuelt/nsm-hever-det-nasjonale-cyberrisikonivaet-til-hoyt) (27.10.2026) | The 21 measures in the alert, and V1 to V7 | The 21 IDs match the alert's list, 2026-11-09 |

`tools/data/gp-ikt-2.1.json` is extracted from the spreadsheet; the spreadsheet itself is not in this repository.
`tools/data/nsm-alert-2026.json` holds the alert's measures.

## Two frameworks

- **`nsm-gp-ikt`**: the 118 measures of GP-IKT 2.1, by NSM's own number, such as `nsm-gp-ikt:2.6.7`.
- **`nsm-varsel-2026`**: measures in the alert's text that have no GP-IKT number, such as phishing-resistant MFA.
  NSM gives them no numbers or titles, so **V1 to V7 and their titles are the author's summary of the alert**, not
  NSM's. They come from NSM's alert of 27 October 2026 and stay in the pack when the alert is lifted, as good
  practice and as a record of what the alert asked for. A new alert becomes a new framework in a new release;
  nothing is removed without a changelog entry.

The framework files in `nsm-gp-ikt/tests/frameworks/` hold identifiers and facts only: ID, principle, priority,
whether the alert lists the measure, and the link to nsm.no. NSM's ISO/IEC 27002:2022 mapping is not in them:
Maester counts related controls as tested, and the report then showed ISO 27002 as a framework with a share
"met", which the pack does not test. They hold no NSM
text, as Maester's guidance for framework files asks. Read a measure on nsm.no through its link.

## The mapping model

NSM's measures are bundles of clauses (a, b, c) that span clients, servers, network equipment and processes. A test
reads one setting in one product. So a link from a test to a measure always says three things:

1. **Which clause.** `2.6.4 a)`, not just `2.6.4`. `Control` in the test still carries NSM's own measure number
   (`nsm-gp-ikt:2.6.4`), because that is the identifier NSM, its spreadsheet and its ISO mapping use. The clause is
   in the catalogue and in the generated documentation.
2. **How strong the link is** (illustrated below).
   - *Direkte* (direct): the setting or state the test reads is what the clause asks for, within the test's scope.
   - *Delvis* (partial): evidence for part of the clause. A policy that is assigned, without the outcome on the
     devices or accounts. One of several things the clause asks for. Or the author's reading of a measure that names
     no such feature.
   - *Indikator* (indicator): points in a direction. The test has no `Control`, carries the tag `NSM-Indikator`,
     and never counts as coverage.
3. **Which scope the verdict holds for.** Every result's second line is `Gjelder: <scope>.`, such as
   "Windows-klienter i Intune". The level says nothing about what is outside the scope.

![How strong a link is: direct, the test reads what the clause asks for, for example 3005 reads the encryption state of each Windows device for 2.7.3, and counts as coverage; partial, evidence for part of the clause, for example 3004 sees ASR policies assigned but not their effect on each device for 3.1.3 b), and counts as coverage; indicator, points in a direction and proves no measure, for example 1010 shows open Entra recommendations, has no Control and is never counted. Every result's second line, Gjelder, names the scope it holds for](images/link-strength.svg)

The catalogue [`tools/data/mapping.json`](../tools/data/mapping.json) is the one place the mapping is kept. For each
test it holds the scope, the Microsoft feature, the Zero Trust pillar, the nearest control in Microsoft cloud
security benchmark (MCSB v1, the taxonomy Defender for Cloud and Azure Policy use), and for each link the clause,
the strength and the reason. The unit tests fail when a test's `Control` or scope differs from the catalogue, and
`tools/generate_docs.py` fails too. A dashboard that reads the Maester results can read the same file.

## Rules for mapping a test

1. **Start from NSM's clause, not from what Graph exposes.** Ask which Microsoft feature *is* the clause, then
   which signal proves it. Do not ask which measure an existing check could be linked to.
2. **Specify the clause whose text the check proves.** For example, 2.6.7 asks for multi-factor authentication and
   accepts one-time passwords, so a check for *phishing-resistant* MFA specifies the alert (V1), not 2.6.7.
3. **Prefer the outcome over the policy.** A test that can only see an assigned policy is *delvis*. *Direkte* needs
   the setting itself (a tenant-wide setting, a Conditional Access policy that is the control) or the state of the
   devices or accounts.
4. **The primary measure first.** Maester takes the first `Control` value that a framework knows as the test's
   benchmark.
5. **No composite scores.** An overall Secure Score, or a count of mixed recommendations, proves no single measure.
   Pick named recommendations and map each, or show the test as an indicator.
6. **Do not force a feature onto a measure.** A plan, a decision or a restore test is attested with evidence and an
   expiry date. `attest` in the catalogue lists the alert's measures a tenant cannot show.
7. **Say so when it is a reading.** The reason in the catalogue says when the link is the author's interpretation.
   It is shown under "Lenker" in the report.

## Severity

Each test's `Severity` decides where Maester puts a failure in its action plan. It follows how directly a failure
helps an attacker, not NSM's priority:

- **High**: a failure opens a direct path to take over an account, gain privileges, run code, or work unseen on the
  domain controllers. For example MFA and phishing-resistant MFA (1001, 1002, 1005), privileged roles (1006,
  1007), user consent (1009), local administrators (1011), legacy authentication (2001), Defender for Identity
  (2004), LAPS, updates, application control, ASR, antivirus and supported Windows (3001–3004, 3007, 3009).
- **Medium**: a second line of defence, hygiene or awareness: registration progress (1003), the methods policy
  (1004), access reviews (1008), managed devices for access (1012), Secure Score recommendations (2002), phishing
  simulations (2003), Outlook add-ins (2005), encryption, inventory, firewall, baseline and compliance (3005,
  3006, 3008, 3010, 3011), and the indicator 1010.

NSM's priority (1, 2 or 3) is shown in [coverage.md](coverage.md) and does not set the severity: 2002 and 3006
measure priority-1 measures but are Medium, because they measure breadth and inventory rather than a direct path.
A new test states which rule it follows in its pull request.

## Every link

Generated from the catalogue by `tools/generate_docs.py`. Do not edit between the markers.

<!-- mapping:start -->
| Test | NSM clause | Strength | Scope | Microsoft feature | Zero Trust pillar | MCSB |
| --- | --- | --- | --- | --- | --- | --- |
| 1001 | V1 | direct | Entra ID-kontoer, pålogging til skyapper | Conditional Access med en phishing-resistent authentication strength | Identities | IM-6, IM-7 |
| 1002 | V1 | partial | Kontoer med katalogroller i Entra ID | Registrerte autentiseringsmetoder (passkey, FIDO2, Windows Hello for Business) | Identities | IM-6 |
| 1003 | V1 | partial | Aktive, lisensierte medlemskontoer i Entra ID | Registrerte autentiseringsmetoder (passkey, FIDO2, Windows Hello for Business) | Identities | IM-6 |
| 1004 | V1 | partial | Entra ID-tenanten | Policyen for autentiseringsmetoder | Identities | IM-6 |
| 1005 | 2.6.7 a) | direct | Entra ID-kontoer, pålogging til skyapper | Conditional Access som krever multifaktorautentisering | Identities | IM-6, IM-7 |
| 1006 | 2.6.5 b) | partial | Katalogroller i Entra ID | Privileged Identity Management: eligible i stedet for permanente rolletildelinger | Identities | PA-1, PA-2 |
| 1007 | 2.6.1 d) | direct | Katalogroller i Entra ID | Privileged Identity Management: godkjenning og begrunnelse ved aktivering | Identities | PA-2 |
| 1007 | 2.6.5 b) | partial | Katalogroller i Entra ID | Privileged Identity Management: godkjenning og begrunnelse ved aktivering | Identities | PA-2 |
| 1008 | 2.6.1 e) | direct | Gjestekontoer i Entra ID | Access reviews (access reviews) for gjester | Identities | PA-4 |
| 1009 | 2.6.4 | partial | Entra ID-tenanten | Innstillinger for user consent til apper | Applications | PA-7 |
| 1010 | 2.6.7 | indicator | Entra ID-tenanten | Anbefalinger i Microsoft Entra | Identities | – |
| 1011 | 2.6.4 a) | direct | Windows-enheter som kobles til Entra ID | Device settings i Entra ID: lokale administratorer på Entra joined-enheter | Endpoints | PA-7 |
| 1012 | 2.2.6 | direct | Entra ID-kontoer, pålogging til skyapper | Conditional Access som krever en compliant enhet eller hybrid joined enhet | Endpoints | IM-7 |
| 2001 | 2.3.3 i) | direct | Entra ID-kontoer, pålogging til skyapper | Conditional Access som blokkerer legacy authentication, eller security defaults | Identities | NS-8, IM-6 |
| 2001 | 2.6.7 a) | partial | Entra ID-kontoer, pålogging til skyapper | Conditional Access som blokkerer legacy authentication, eller security defaults | Identities | NS-8, IM-6 |
| 2002 | 2.3.3 | partial | Exchange Online, SharePoint og Teams, Windows-klienter i Defender for Endpoint og lokal AD i Defender for Identity | Navngitte anbefalinger i Microsoft Secure Score som slår av eldre protokoller og unødvendige funksjoner | Applications | NS-8, PV-2 |
| 2003 | V7 | partial | Ansatte med postboks i Microsoft 365 | Angrepssimulering (attack simulation training) i Defender for Office 365 | Identities | – |
| 2004 | 3.2.3 a) | partial | Domenekontrollere i lokal Active Directory | Sensor for Microsoft Defender for Identity | Identities | LT-1, LT-2 |
| 2004 | 3.2.4 a) | partial | Domenekontrollere i lokal Active Directory | Sensor for Microsoft Defender for Identity | Identities | LT-1, LT-2 |
| 2005 | 2.8.4 | direct | Outlook i Exchange Online | Role assignment policy i Exchange Online: brukere kan ikke installere Outlook-tillegg | Applications | PV-2 |
| 3001 | 2.3.7 | partial | Windows-klienter i Intune | Windows LAPS styrt av Intune og slått på i Entra ID | Endpoints | PA-1 |
| 3002 | 2.3.1 d) | partial | Windows-klienter i Intune | Update rings i Windows Update for Business | Endpoints | PV-6 |
| 3003 | 2.3.2 a) | partial | Windows-klienter i Intune | App Control for Business, eller AppLocker | Endpoints | AM-5 |
| 3004 | 3.1.3 b) | partial | Windows-klienter i Intune | Attack surface reduction-regler (ASR) i Microsoft Defender | Endpoints | ES-1 |
| 3004 | 2.3.2 d) | partial | Windows-klienter i Intune | Attack surface reduction-regler (ASR) i Microsoft Defender | Endpoints | ES-1 |
| 3005 | 2.7.3 | direct | Windows-klienter i Intune | BitLocker, lest som krypteringsstatus per enhet | Data | DP-4 |
| 3006 | 1.2.3 a) | partial | Windows-enheter i Entra ID | Enhetsoversikten i Entra ID, med forvaltningsstatus | Endpoints | AM-1 |
| 3007 | 2.1.2 a) | partial | Windows-klienter i Intune | Windows-versjon per enhet | Endpoints | – |
| 3008 | 2.4.4 a) | partial | Windows-klienter i Intune | Windows-brannmuren styrt av en Endpoint security-policy i Intune | Network | – |
| 3009 | 3.1.3 a) | partial | Windows-klienter i Intune | Microsoft Defender Antivirus styrt av en Endpoint security-policy i Intune | Endpoints | ES-2 |
| 3010 | 2.3.4 a) | partial | Windows-klienter i Intune | Security baseline i Intune, eller en baseline i Settings catalog | Endpoints | PV-3 |
| 3011 | 2.3.5 d) | partial | Windows-klienter i Intune | Compliance policies for enheter i Intune | Endpoints | PV-4 |
<!-- mapping:end -->

## Microsoft features with a direct signal and no test yet

`planned` in the catalogue lists them, with the signal and what it needs. The larger ones need services beyond
Microsoft Graph (Azure Resource Manager, Exchange Online) or `ThreatHunting.Read.All`, which the pack does not
declare today. Azure resources are measured by the [Azure Policy initiative for GP-IKT 2.1](https://github.com/alventech/azure-policy-nsm-gp-ikt), not by this pack.

## Changes to the mapping

| Date | Change |
| --- | --- |
| 2026-11-09 | Review against NSM's text. 1002: 2.6.5 → 2.6.7. 1008: 2.1.9, V4 → 2.6.1, 2.6.3. 1010: dropped 2.3.3. 2004: 2.6.5 → 3.2.3. 3001: dropped 2.6.4 (not scored). 3005: added 2.7.3 first. |
| 2026-11-11 | Clause by clause review (0.3.0). Every link has a clause, a strength and a scope. 1001 to 1004: V1 only, 2.6.7 dropped (2.6.7 accepts one-time passwords; 1005 measures it). 1006: 2.6.5 b only, 2.6.4 dropped (a role holder is an operator, not an end user). 1007: 2.6.1 d first. 1008: 2.6.1 e only, 2.6.3 dropped (c, d and e are not measured). 1009: 2.6.4 only, V5 dropped (restricting consent maps nothing). 1010: an indicator without `Control`. 2002: mail forwarding removed, Outlook add-ins moved to the new 2005 (2.8.4). 3004 split: ASR stays (3.1.3 b, 2.3.2 d), firewall is 3008 (2.4.4), antivirus is 3009 (3.1.3 a), baseline is 3010 (2.3.4). 3005 split: encryption stays (2.7.3), compliance is 3011 (2.3.5). New: 1011 (2.6.4 a, local administrators on joined devices), 1012 (2.2.6, managed device in Conditional Access). 2.3.3 goes from four tests to two, 2.6.7 from seven to one direct and one partial. |

## Coverage

See [coverage.md](coverage.md) for every measure and the tests that name it.
