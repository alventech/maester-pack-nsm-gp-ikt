# NSM GP-IKT 2.1: NSM's ICT Security Principles (Maester Pack)

A [Maester](https://maester.dev) pack that measures how far a Microsoft 365 tenant has come with the measures in
*NSM's ICT Security Principles* (Grunnprinsipper for IKT-sikkerhet, GP-IKT) 2.1, and with the extra measures in
NSM's alert of 27 October 2026 that raised the national cyber risk level to HIGH. The pack reads Entra ID,
Microsoft 365, Intune and Defender through Microsoft Graph. It never writes to the tenant.

Each result is scored on NSM's own scale from its risk assessment template, *høy*, *moderat* or *liten grad*
(high, moderate or low degree), and links to the measure on nsm.no. What a user sees in a Maester run (test titles,
results and test documentation) is in Norwegian, NSM's language; see [language](https://github.com/alventech/maester-pack-nsm-gp-ikt/blob/main/docs/language.md).

> **A free community pack.** Free to use and change under the MIT licence, and open to contributions from anyone.
> It is not a product of the Norwegian National Security Authority (NSM), the Maester project, Microsoft or any
> company, and it is not made, reviewed or endorsed by NSM. It comes with no support agreement or warranty. Which
> measure a test belongs to is the author's reading of NSM's text (see [how the tests map to NSM](https://github.com/alventech/maester-pack-nsm-gp-ikt/blob/main/docs/mapping.md)).
> A result is input to an assessment, not a statement of compliance.

## What the pack covers

GP-IKT 2.1 has 118 measures, and most are about governance and processes, or about systems that Microsoft Graph
does not show: servers, network equipment, OT and on-premises Active Directory (Maester reads AD through its own
connection; a separate NSM pack for AD is planned). The pack tests what Microsoft Graph shows: 28 tests that answer clauses of 19 GP-IKT measures and two
of the alert's extra measures. [Coverage](https://github.com/alventech/maester-pack-nsm-gp-ikt/blob/main/docs/coverage.md) shows what is measured and what is not.

**A test answers one clause of a measure, within one scope.** NSM's measures apply to clients, servers, network
equipment and processes, so no test covers a whole measure. Each link from a test to a measure is marked *direct*,
*partial* or *indicator*, and each result says what it holds for.

<!-- tests:start -->
| Test | Title (Norwegian, as in the report) | NSM | Domain | Severity |
| --- | --- | --- | --- | --- |
| MP.NSM.1001 | Conditional Access krever phishing-resistent MFA for alle brukere og apper | V1 | Identity | High |
| MP.NSM.1002 | Alle administratorer har registrert en phishing-resistent metode | V1 | Identity | High |
| MP.NSM.1003 | Brukerne har registrert en phishing-resistent metode | V1 | Identity | Medium |
| MP.NSM.1004 | Authentication methods-policyen tillater passkeys og slår av SMS, tale og Email OTP | V1 | Identity | Medium |
| MP.NSM.1005 | Conditional Access krever MFA for alle brukere og alle apper | 2.6.7 | Identity | High |
| MP.NSM.1006 | Privilegerte roller er ikke tildelt permanent | 2.6.5 | Identity | High |
| MP.NSM.1007 | Privilegerte roller aktiveres i PIM med godkjenning | 2.6.1, 2.6.5 | Identity | High |
| MP.NSM.1008 | Gjester og leverandørtilganger gjennomgås jevnlig | 2.6.1 | Identity | Medium |
| MP.NSM.1009 | Brukere kan ikke gi samtykke til ukjente apper | 2.6.4 | Identity | High |
| MP.NSM.1010 | Ingen aktive høyprioritets anbefalinger i Entra | – (indicator) | Identity | Medium |
| MP.NSM.1011 | Brukere blir ikke lokal administrator når de kobler en enhet til Entra ID | 2.6.4 | Endpoint | High |
| MP.NSM.1012 | Conditional Access krever en forvaltet enhet for tilgang til tjenestene | 2.2.6 | Identity | Medium |
| MP.NSM.2001 | Legacy authentication er blokkert | 2.3.3, 2.6.7 | Microsoft 365 | High |
| MP.NSM.2002 | Unødvendig og usikker funksjonalitet er slått av (Secure Score-anbefalinger) | 2.3.3 | Microsoft 365 | Medium |
| MP.NSM.2003 | Phishing-simulering er kjørt siste kvartal | V7 | Organisation | Medium |
| MP.NSM.2004 | Defender for Identity overvåker domenekontrollerne | 3.2.3, 3.2.4 | On-premises | High |
| MP.NSM.2005 | Brukere kan ikke installere Outlook-tillegg selv | 2.8.4 | Microsoft 365 | Medium |
| MP.NSM.3001 | Windows LAPS styres av Intune på alle enheter | 2.3.7 | Endpoint | High |
| MP.NSM.3002 | Windows-oppdateringer styres sentralt, og enhetene synkroniserer med Intune | 2.3.1 | Endpoint | High |
| MP.NSM.3003 | Applikasjonskontroll hindrer ukjent programvare | 2.3.2 | Endpoint | High |
| MP.NSM.3004 | Attack surface reduction-regler (ASR) er tildelt Windows-klientene | 3.1.3, 2.3.2 | Endpoint | High |
| MP.NSM.3005 | Windows-enhetene er kryptert | 2.7.3 | Endpoint | Medium |
| MP.NSM.3006 | Aktive Windows-enheter er kjent og forvaltet | 1.2.3 | Endpoint | Medium |
| MP.NSM.3007 | Windows-enhetene kjører en versjon med støtte | 2.1.2 | Endpoint | High |
| MP.NSM.3008 | Brannmuren på Windows-klientene styres av Intune | 2.4.4 | Endpoint | Medium |
| MP.NSM.3009 | Antivirus på Windows-klientene styres sentralt av Intune | 3.1.3 | Endpoint | High |
| MP.NSM.3010 | Windows-klientene har en standard sikkerhetskonfigurasjon (security baseline) | 2.3.4 | Endpoint | Medium |
| MP.NSM.3011 | Windows-enhetene oppfyller virksomhetens compliance policies | 2.3.5 | Endpoint | Medium |
<!-- tests:end -->

Every level, licence and permission per test is in the [test reference](https://github.com/alventech/maester-pack-nsm-gp-ikt/blob/main/docs/tests.md).

## How it differs from Maester's own tests

Maester has its own tests that read 17 of the same settings, against CISA, CIS or Maester's rules. The pack measures
NSM's measures on NSM's scale, says what the verdict holds for, and links to the measure at NSM. It often gives
*moderat grad* where Maester says Failed, and it is stricter on user consent to apps (1009) and ASR rules (3004).
10 of the tests have no counterpart in Maester. You can run both: `Invoke-Maester -Pack NSM -SkipGraphConnect`. The
comparison, test by test: [docs/maester-comparison.md](https://github.com/alventech/maester-pack-nsm-gp-ikt/blob/main/docs/maester-comparison.md).

## Prerequisites

- **Maester 3.0 or later.** Maester 3.0 is in preview: `Install-Module Maester -AllowPrerelease`. On Maester 2.x,
  the same tests come as custom tests in `nsm-gp-ikt-maester2-<version>.zip` on each release; see the README in it.
- **PowerShell 7.4 or later,** which Maester 3.0 requires.
- **An account that can read the tenant,** for example with the Global Reader role.
- **Licences** for the products a test reads:

| Area | Requires | Tests |
| --- | --- | --- |
| Conditional Access, registration report | Entra ID P1 | 1001, 1002, 1003, 1005, 1012, 2001 |
| PIM, access reviews | Entra ID P2 or Entra ID Governance | 1007, 1008 |
| Devices | Microsoft Intune | 3001–3005, 3007–3011 |
| Defender for Identity | Defender for Identity | 2004 |
| Phishing simulation | Defender for Office 365 Plan 2 | 2003 |

When the tenant lacks the licence, the test is skipped with a reason. The same happens when the connection lacks a
permission. Neither gives *liten grad*.

## Install

```powershell
Install-Module Maester -AllowPrerelease -Scope CurrentUser
Install-MtPack alventech/maester-pack-nsm-gp-ikt/nsm-gp-ikt
```

`Install-MtPack` shows what the pack reaches and its risk before you approve, and pins the version in
`maester-packs.lock.json`. A new version can be installed 72 hours after it is published.

## Connect

The pack needs read permissions in Microsoft Graph only. `Connect-Maester` asks for most of them; add the rest when
you connect:

```powershell
$scopes = (Get-MtGraphScope) + 'AttackSimulation.Read.All', 'RoleManagementPolicy.Read.Directory', 'SecurityEvents.Read.All'
Connect-MgGraph -Scopes $scopes
```

Sign-in happens in the browser. Do not use `-UseDeviceCode`: device code sign-in is a known phishing route and is
often blocked by Conditional Access.

The permissions each test needs are in the [test reference](https://github.com/alventech/maester-pack-nsm-gp-ikt/blob/main/docs/tests.md). To run without a user, grant the
permissions in `maester-pack.json` (`Uses.GraphScopes`) to a managed identity or an app as application
permissions; see [permissions](https://github.com/alventech/maester-pack-nsm-gp-ikt/blob/main/docs/permissions.md).

## Run

```powershell
Invoke-Maester -Pack NSM -SkipBuiltIn -SkipGraphConnect    # only this pack, with the connection above
Invoke-Maester -Pack NSM -SkipGraphConnect                 # together with Maester's own tests
```

`-SkipGraphConnect` uses the connection you made, instead of checking the permissions of all of Maester's built-in
tests.

## Settings

Set under `GlobalSettings` in `maester-config.json`; [maester-config.example.json](https://github.com/alventech/maester-pack-nsm-gp-ikt/blob/main/maester-config.example.json) has all four:

| Setting | Default | Used by |
| --- | --- | --- |
| `EmergencyAccessAccounts` | none | 1002, 1005, 1006. Maester's own setting: the emergency access accounts, with `Id` or `UserPrincipalName`. They are left out of the counts. |
| `NsmGpIkt.BaselinePolicyPattern` | `(?i)\bCIS\b\|baseline` | 3010. A regular expression for the names of policies that count as a security baseline. |
| `NsmGpIkt.MinimumWindowsBuild` | `26100` | 3007. The lowest Windows build counted as supported (26100 is Windows 11 24H2, supported for Enterprise and Education until October 2027). |
| `NsmGpIkt.AllowedWindowsBuilds` | none | 3007. Builds below the minimum that you run with support, such as Windows LTSC: `[17763, 19044]`. |

## Reading the results

- The first line of each result is `NSM-vurdering: Høy grad.`, `Moderat grad.` or `Liten grad.`
- The second line is `Gjelder: <scope>.`, for example "Windows-klienter i Intune" (Windows clients in Intune). The
  level says nothing about what is outside that scope.
- **Only *høy grad* passes.** *Moderat* and *liten grad* fail, so that the Maester report shows what is left.
- Each test names its NSM measures in `Control`, such as `nsm-gp-ikt:2.6.7` or `nsm-varsel-2026:V1`. The
  frameworks view in the report shows the results per measure. The link to the measure on nsm.no is under
  "Lenker" (links) in each test.
- Under "Lenker", each NSM measure says whether the link is *direkte* (direct) or *delvis* (partial), and why. A test
  tagged `NSM-Indikator` has no `Control`: it shows a direction and does not count as coverage of any measure.
- The tag `NSM` is on every test, and `NSM-Identitet`, `NSM-M365`, `NSM-Endepunkt` or `NSM-On-prem` gives the area.
- Maester's own report interface (tabs, filters, *Passed*/*Failed*, severity) is in English.

The results contain names of policies, roles and accounts from the tenant. Treat the report files as internal.

## Troubleshooting

Keyed by what you see in the report.

- **Skipped, *NotAuthorized*.** The connection lacks a permission the test needs, or the account lacks a role that
  can read it. Add the scope from the test's `Permission` (see the [test reference](https://github.com/alventech/maester-pack-nsm-gp-ikt/blob/main/docs/tests.md))
  and connect again. 1011 and 3001 read `policies/deviceRegistrationPolicy`; if `Policy.Read.All` is not enough in
  your tenant, add `Policy.Read.DeviceConfiguration`.
- **Skipped because a licence is missing** (*LicenseNotFound* on Maester 3; *NotLicensedIntune* and similar on
  Maester 2). The tenant lacks the licence in the test's `License`. This is expected and does not lower the level of other tests.
- **Skipped, *ServiceNotConnected*.** Maester has no Microsoft Graph connection. Connect as above and run with
  `-SkipGraphConnect`.
- **Error with 502, 503 or 504 from Graph.** A Microsoft Graph outage, most often in Secure Score (2002, 2005) or
  attack simulations (2003). Run again later; the pack does not turn an outage into a level.
- **`Install-MtPack` says the cooldown is not met.** A new release can be installed 72 hours after it is published.
  `-IncludeRecent` installs it sooner, after you have read what changed.
- **A level you disagree with.** Open a "Wrong verdict" issue with the test ID, the kind of tenant (licences,
  cloud-only or hybrid; never its name, domain or IDs) and what the portal shows; see [CONTRIBUTING.md](https://github.com/alventech/maester-pack-nsm-gp-ikt/blob/main/CONTRIBUTING.md).

## Support

The pack is maintained voluntarily, with no promised response time. Report a fault in a test or in the pack as an
issue in the repository. Report security problems as [SECURITY.md](https://github.com/alventech/maester-pack-nsm-gp-ikt/blob/main/SECURITY.md) describes.
