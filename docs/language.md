# Language

Decided 2026-11-12: **what a user sees in a Maester run is Norwegian. English comes when someone asks for it.**
Changed 2026-11-17: **every README and document is English**, including the pack's README and the Maester 2 README,
so the repository reads the same throughout.

## Why the run is Norwegian

- GP-IKT is a Norwegian framework, and the pack is mainly meant for Norwegian organisations that follow NSM's
  guidance. The people who act on a result usually work from NSM's Norwegian text.
- NSM's scale (*høy*, *moderat*, *liten grad*) and the measure titles are quoted as NSM writes them. A translation
  would be the author's wording next to NSM's, which invites "is that what NSM means?".
- One language halves the text to keep correct. Every verdict line, scope line and test document would otherwise
  need a second version that is checked in a tenant too.

## What is in which language

| Text | Language | Reader |
| --- | --- | --- |
| Test titles, verdict lines (`NSM-vurdering: …`), scope lines (`Gjelder: …`), result tables | Norwegian | Whoever reads the Maester report |
| Test documentation (`Test.MP.NSM.*.md`), including the heading *Lenker* | Norwegian | Same |
| The heading `#### Remediation action` in each test document | **English** | Maester's report splits the document on it, see below |
| `maester-pack.json` `Name` and `Description`, the guide (`maester-pack.guide.json`) | Norwegian | People browsing packs.maester.cloud and reading the report |
| The pack's `README.md` and the Maester 2 README (titles in its test table stay Norwegian, as the report shows them) | English | People installing the pack |
| `feature` and `planned` in `tools/data/mapping.json` (the Microsoft feature a test reads, the checks still to come) | Norwegian, with Microsoft's product names | Shown in the generated docs |
| Maester's own report interface: tabs, filters, *Passed*/*Failed*, severity | **English** | Not ours to change, see below |
| Repository README, `docs/` (this file, mapping method, verification, permissions), code comments | English | Contributors and Maester's maintainers, who review packs and do not all read Norwegian |

The rule: text a user of the pack sees in a Maester run is Norwegian. Every README and document is English.

## Microsoft's terms stay in English

Admins in Norway use the Microsoft portals in English, and Microsoft's own Norwegian translations (*eldre
godkjenning*, *godkjenningsstyrke*) are words nobody uses. A translated feature name sends the reader looking for
something they cannot find, and in one case said the opposite of Microsoft's term ("Solicited Remote Assistance"
became *uoppfordret*, unsolicited). So, decided 2026-11-13 after a customer demo:

- **Feature and setting names stay as in the portal:** legacy authentication, security defaults, report-only,
  authentication strength, authentication context, Authentication methods-policyen, compliant, compliance
  policy, hybrid joined, co-managed, eligible (PIM), access reviews, user consent, admin consent workflow,
  verified publishers, update rings, Endpoint security, Settings catalog, security baseline, attack surface
  reduction, audit/block-modus, managed installer, Device settings, Conditional Access conditions (locations,
  device platforms, client apps, risk, filter for devices), and Secure Score recommendation names.
- **Norwegian where it is ordinary Norwegian:** *bruker*, *enhet*, *tildelt*, *gjest*, *pålogging*, *kryptert*,
  *brannmur*, *nødtilgangskontoer*.
- **NSM's own words stay as NSM writes them:** *forvaltet*, *programtillegg*, *eldre eller ubrukte protokoller*,
  *høy/moderat/liten grad*.
- **When unsure, use the English term.** A Norwegian sentence with an English term reads naturally to an admin; a
  wrong Norwegian term does not.

## Why parts of the Maester report stay English

Maester (checked on 3.0.0-rc83, 2026-11-12) has no language setting:

- The report (`assets/ReportTemplate.html`) is one English-only web page.
- A test has one `Title` and one `.md` file. There is no way to ship a title or a document in two languages.
- Maester's report reads one heading in a test's `.md` file: the one that starts with *Remediation*, *How to fix* or
  *Investigation steps*. Everything above it shows as "Why it matters", and everything from it shows on the
  "How to fix" tab. With a Norwegian heading (*Slik retter du det*, used until 2026-11-13) the report could not
  split the document and showed all of it in both places. The heading is therefore `#### Remediation action`, as in
  Maester's own tests. Other headings are not read, so *Lenker* stays Norwegian.

So the pack is Norwegian where it controls the text, and Maester's interface around it is English.

**Rejected: translating Maester's report afterwards.** A script could rewrite the HTML report after each run
and add a language toggle. It was rejected because:

- it lives outside the pack, so people who install the pack would not get it;
- it depends on the text of Maester's interface, which changes in almost every release candidate, and it would
  break without anyone noticing;
- it would not translate the pack's own text, which Maester stores as one string.

## When someone asks for English

1. **The source.** NSM publishes an official English edition, [NSM ICT Security Principles v2.1](https://nsm.no/getfile.php/1313972-1717589707/NSM/Filer/Dokumenter/Veiledere/NSM%20ICT%20Security%20Principles%20v2.1.pdf).
   It was completed on 31 May 2024 and has the same content as the Norwegian 2.1, apart from two illustrations.
   NSM points to [nsm.no/ict-sp](https://nsm.no/ict-sp) for more English material, including a spreadsheet of the
   measures. Use NSM's English measure titles, not a translation of our own. Read the numbering from the
   spreadsheet and check it against `tools/data/gp-ikt-2.1.json` before using it.
2. **The pack** needs one of two things:
   - Maester supports languages in packs (it does not today), and the pack adds English titles and
     documents next to the Norwegian ones; or
   - an English pack **in this same repository**: a second folder, `nsm-gp-ikt-en/`, next to `nsm-gp-ikt/`, with
     its own `maester-pack.json` (`Id` `alventech.nsm-gp-ikt-en`, its own `Guid` and `Code`), the same checks and
     English titles and documents. Users install it with `Install-MtPack alventech/maester-pack-nsm-gp-ikt/nsm-gp-ikt-en`.
     The helpers stay in one place and are copied into both folders by a tool, and each pack is released with its
     own tag (`nsm-gp-ikt-en-v<version>`), as other community repositories with several packs do. Every fix to a
     check then goes into both packs' text, which is why it is not done in advance. The planned on-premises
     Active Directory pack (`nsm-gp-ikt-ad/`) follows the same layout.
