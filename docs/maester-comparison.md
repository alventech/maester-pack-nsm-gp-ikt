# The pack and Maester

What this pack adds to Maester, how it differs from Maester's own tests that read the same settings, and what a
user sees on Maester 3 and on Maester 2.

## In short

- **The pack measures NSM, not a benchmark.** Maester's own tests check a setting against CISA, CIS or Maester's
  rule and say pass or fail. The pack says how far the tenant meets an NSM measure, on NSM's scale (*høy*,
  *moderat*, *liten grad*), what part of the measure the verdict holds for (*Gjelder*), and links the measure on
  nsm.no. Only *høy grad* passes.
- **18 of the 28 tests have a related Maester test (17 read the same setting); 10 have none.** Where both run, they
  often agree on fail, but the pack gives partial credit (*moderat grad*) where Maester fails, and is stricter in
  two places. See [the table](#the-pack-next-to-maesters-own-tests).
- **Maester 3 and Maester 2 give the same results.** Every result, level, scope, result text and description is
  the same. Maester 2's report shows less around them: no pack page, guide, frameworks, products, ATT&CK or action
  plan.

Disagree with a level? Open a "Wrong verdict" issue: see [CONTRIBUTING.md](../CONTRIBUTING.md).

## The pack next to Maester's own tests

The pack does not run or replace Maester's tests; run both with `Invoke-Maester -Pack NSM -SkipGraphConnect`.
For 17 tests the related test is the one whose ATT&CK techniques the pack copies (`mitre.sameAs` in
[tools/data/mapping.json](../tools/data/mapping.json)); 3007's is only related and lends no techniques.

| Pack test | Maester test | How they differ |
| --- | --- | --- |
| 1001 Phishing-resistant MFA in Conditional Access | CISA.MS.AAD.3.1 | Maester needs a policy for all users that is on. The pack gives *moderat* for policies that cover some users or apps, or are report-only. |
| 1002 Admins have registered a phishing-resistant method | CISA.MS.AAD.3.6 | Maester checks for a policy that requires it for admins; the pack counts the admins who have registered a method. |
| 1003 Users have registered a phishing-resistant method | CISA.MS.AAD.3.1 | Different questions: the pack counts registrations, Maester checks that Conditional Access enforces them. |
| 1004 Authentication methods: passkeys on, SMS, voice and Email OTP off | CISA.MS.AAD.3.5 | Both fail on SMS, voice or Email OTP. The pack does not score Email OTP for guests, a separate setting, and also needs passkeys with attestation. |
| 1005 Conditional Access requires MFA for everyone | MT.1007 | The pack also checks exclusions and conditions that narrow the policy. |
| 1006 No permanent privileged role assignments | CISA.MS.AAD.7.4 | The pack leaves out the emergency access accounts in `EmergencyAccessAccounts`; Maester lists them. |
| 1007 PIM activation with approval | CISA.MS.AAD.7.6 | The pack also needs privileged roles to be eligible and activation to need MFA or an authentication context. |
| 1008 Guest access reviews | CIS.M365.5.3.2 | The pack treats a tenant without guests as not applicable. |
| 1009 Users cannot consent to unknown apps | CIS.M365.5.1.5.1 | **The pack is stricter.** Microsoft's recommended consent policy (verified publishers, low-risk permissions) passes CIS; NSM 2.6.4 asks to minimise end-user rights, so the pack gives *høy grad* only when users cannot consent at all. |
| 1011 Users do not become local admin on Entra join | MT.1091 | The same setting. |
| 1012 Conditional Access requires a managed device | CISA.MS.AAD.3.7 | As 1001: partial or report-only policies give *moderat*. |
| 2001 Legacy authentication is blocked | MT.1010 | Maester checks Exchange ActiveSync only. The pack checks all legacy clients and gives *moderat* when the block is report-only or partial. |
| 2005 Users cannot install Outlook add-ins | MT.1041 | The same setting, but Maester needs an Exchange Online connection; the pack reads it from Secure Score through Graph and runs with Graph only. |
| 3001 Windows LAPS managed by Intune | MT.1177 | Maester checks the LAPS settings (backup, complexity, length). The pack checks assignment to all devices and that Entra ID allows LAPS. |
| 3003 Application control | MT.1179 | Maester looks for App Control for Business only; the pack gives *moderat* for AppLocker. |
| 3004 ASR rules assigned | MT.1178 | **The pack is stricter on scope.** Maester passes when the baseline rules are set in some policy; the pack gives *høy grad* only when the policy is assigned to all devices. |
| 3005 Windows devices are encrypted | MT.1123 | Maester checks the BitLocker policy settings; the pack measures the outcome, the share of encrypted devices. |
| 3007 Supported Windows versions | MT.1102 | Related, not the same: MT.1102 checks that feature update policies do not target unsupported builds; the pack checks the build each device runs. |

No Maester counterpart: 1010 (Entra recommendations), 2002 (Secure Score recommendations for unneeded features),
2003 (phishing simulation), 2004 (Defender for Identity on domain controllers), 3002 (update rings and check-in),
3006 (devices known and managed), 3008 (firewall), 3009 (antivirus), 3010 (security baseline), 3011 (compliant
devices). These are what the pack adds beyond a different scale.

## Maester 3 and Maester 2

Maester exists in two versions today:

- **Maester 2** (2.3.0) is the current stable release: what `Install-Module Maester` installs.
- **Maester 3** is in preview (`Install-Module Maester -AllowPrerelease`). It adds **packs**: a folder of tests with
  a manifest (`maester-pack.json`) that `Install-MtPack` checks, pins and installs, and that the report shows with
  its own menu, guide and framework view. This repository's `nsm-gp-ikt/` folder is such a pack.

Maester 2 does not know about packs: it has no `Install-MtPack`, and it cannot read `maester-pack.json`. What it has
is **custom tests**: Pester test files you put in the `tests/Custom/` folder of your Maester folder, which
`Invoke-Maester` runs together with Maester's own tests. So that the pack is useful before Maester 3 is released,
each release also has a zip, `nsm-gp-ikt-maester2-<version>.zip`, with the same 28 tests in that form. Unpack it
into `tests/Custom/` and run Maester 2 as usual.

The tests themselves are the same files. Run against the same tenant, the two give the same result, level, scope,
text and description for every test. What differs is what Maester draws around the results:

| In the report | Maester 3 (pack) | Maester 2 (custom tests) |
| --- | --- | --- |
| Result, NSM level and *Gjelder* | Yes | Yes, identical |
| The test's description and fix | Tabs: *Finding*, *Why it matters*, *How to fix* | One *Test details* block with the whole document, fix and links included |
| Licence check | Maester, from the test's `License` | The build's shim, same licences, Maester 2's skip reasons |
| Settings (`maester-config.json`) | `Get-MtSetting` | The build's shim, same `GlobalSettings` |
| Pack page and menu (*Oversikt*, *Alle tester*, *Gjenstår*, *Høy grad*) | Yes | No; one list of all tests |
| Guide (*Forutsetninger*, *Koble til*, *Kjøre*, settings table) | Yes | No; see the README in the zip |
| Frameworks view: NSM measures met and not met | Yes (nsm-gp-ikt, nsm-varsel-2026) | No; the measures are only links in each test |
| Product, feature and area of each test | Yes, with icons and filters | No; the category is the pack name |
| ATT&CK techniques | Yes, 17 tests | No |
| Action plan, quick wins, user impact and effort | Yes | No |
| Pack name, version, publisher and risk | Yes | No |
| Exports | Export menu | Markdown, Excel, print |

One rendering difference in Maester 2: inline code in a description shows its backticks
(`` `RoleManagementPolicy.Read.Directory` ``).

## What the Maester 2 build does that Maester 3 does itself

| Maester 3 | The Maester 2 build ([maester2/NsmMaester2.ps1](../maester2/NsmMaester2.ps1), [tools/build_maester2.py](../tools/build_maester2.py)) |
| --- | --- |
| Reads the `[MaesterTest()]` attribute | Removes it, since Maester 2 cannot call a function that carries it, and writes its title, tags, severity and licences into one Pester file per test |
| `Get-MtSetting` | Reads `GlobalSettings` from the run's config the same way |
| Skips a test when the tenant lacks its `License` | The same check with the same service plan and SKU IDs (a unit test compares them with Maester 3's table) |
| Shows the test's `.md` | Adds the `.md` to every result, which Maester 2 would miss because the results are written from a helper |

## How to compare in your own tenant

Connect once with the pack's Graph permissions (see [permissions.md](permissions.md)), then:

```powershell
# Maester 3: the pack, and Maester's related tests
Invoke-Maester -Pack NSM -SkipBuiltIn -SkipGraphConnect -OutputFolder ./m3
Invoke-Maester -TestId CISA.MS.AAD.3.1, CISA.MS.AAD.3.5, MT.1007 -SkipGraphConnect -OutputFolder ./m3-builtin   # the IDs in the table

# Maester 2.3.0, in a new PowerShell session: the zip unpacked into ./tests/Custom/NSM
Invoke-Maester -Path ./tests -Tag NSM -SkipGraphConnect -OutputFolder ./m2
```

Then compare the `TestResults-*.json` files by test ID. The reports hold your tenant's data: keep them out of
public issues.
