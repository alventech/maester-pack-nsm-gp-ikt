# Verifying the pack

A release is ready when the pack runs correctly in tenants that differ from the one it was written in, and its
verdicts match what an admin sees in the portals. This page says how to check that, and what has been
checked.

## Two kinds of check

| Check | Proves | How |
| --- | --- | --- |
| **Smoke test** | Every test runs, reports its level by the pack's rules, and skips with a reason when it cannot measure. | `scripts/Invoke-NsmPackSmokeTest.ps1`, automatic. |
| **Verdict check** | The level is right for the tenant. | An admin compares each result with the portal, by hand. |

A tenant with poor security passes the smoke test. The smoke test checks the pack, not the tenant.

## Run the smoke test

From the repository root, in PowerShell 7.4 with Maester 3.0:

```powershell
./scripts/Invoke-NsmPackSmokeTest.ps1 -TenantId contoso.onmicrosoft.com                                         # browser sign-in
./scripts/Invoke-NsmPackSmokeTest.ps1 -TenantId <tenant-id> -ClientId <app-id> -CertificateThumbprint <thumbprint>   # app-only
./scripts/Invoke-NsmPackSmokeTest.ps1 -SkipConnect -Config ./maester-config.json                                   # existing connection
```

The script runs `Test-MtPack`, signs in, runs the source with `Invoke-MtTest -Path` (nothing is installed), and
checks every result:

- no test ends in **Error**;
- a passed or failed test starts with `NSM-vurdering: Høy | Moderat | Liten grad`, and only *høy grad* passes;
- a passed or failed test states its scope on the second line (`Gjelder: …`);
- a skipped test gives a reason;
- every `Control` is a requirement in the framework files.

It writes `smoke-summary.json` and `smoke-summary.md` to `smoke-results/<timestamp>/` and exits with 1 when a check
fails. The summary holds test IDs, results and levels, not the tenant's data, but it does hold the tenant ID: keep
it out of public issues.

## Tenants to test

Each profile catches a different kind of fault. A release should pass the smoke test in at least the first four.

| # | Tenant profile | What it catches | Expected |
| --- | --- | --- | --- |
| 1 | Mature: E5, Intune, Entra ID P2, Defender for Identity and Office P2, hybrid AD | Wrong verdicts when everything is there | Every test runs |
| 2 | Business Premium or E3: Entra ID P1, Intune, no P2, no MDO P2, no MDI | Missing licences | 1007, 1008, 2003, 2004 skip with a reason; none fail as *liten grad* for lack of a licence. 2002 says how many of its recommendations the tenant has |
| 3 | Cloud-only, no on-premises AD | Tests that assume on-premises | 2004 skips as not applicable |
| 4 | App-only run against tenant 1 or 2 | Endpoints that behave differently without a user | Same results as delegated |
| 5 | Default `Connect-Maester` scopes only | Missing scopes | Tests without their scope skip as not authorised, none error or score wrongly. Check 1011 and 3001: they read `policies/deviceRegistrationPolicy` with `Policy.Read.All`; if Graph refuses, the least privileged scope is `Policy.Read.DeviceConfiguration` |
| 6 | Large: 10 000+ users or devices | Paging, throttling, run time | Same rules hold; note the run time |
| 7 | Co-managed devices or Windows LTSC | Device verdicts | Compare 3005 and 3007 with Intune |
| 8 | Empty trial tenant | Empty collections | No errors |

## Verdict check

For every test that ran, an admin opens the place in the portal the test reads and confirms the level. The test's
documentation (`Test.MP.NSM.<n>.md`) says what *høy*, *moderat* and *liten grad* mean for it.

Record a mismatch as an issue with the test ID, the tenant profile (the kind of tenant in the table above; never its name, domain or IDs) and what the portal shows.

## What has been verified

| Tenant profile | Auth | Maester | Smoke test | Result |
| --- | --- | --- | --- | --- |
| 1 (mature) | Delegated, all 12 scopes | 3.0.0-rc83 | Passed | 28 ran, 0 errors, 0 skipped |
| 4 (app-only against profile 1) | App-only, certificate, the 12 scopes in `Uses.GraphScopes` | 3.0.0-rc83 | Passed | The same results as delegated |
| 4 (app-only against profile 1) | App-only, certificate | 2.3.0 (the Maester 2 build) | – | The same results, levels and texts as Maester 3 |

Profiles 2, 3 and 5 to 8 have not been run in a tenant. The faults they target are covered by the unit tests in
`unit-tests/` (mocked Graph responses).

**Help wanted:** if you run the pack in one of those profiles, open an issue with the profile, the Maester version
and the smoke test's `smoke-summary.md` with the tenant ID removed. A verdict that does not match the portal is a
"Wrong verdict" issue: see [CONTRIBUTING.md](../CONTRIBUTING.md).
