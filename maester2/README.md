# NSM GP-IKT 2.1 for Maester 2

The same 28 tests as the Maester pack `alventech.nsm-gp-ikt`, for Maester 2.x.

Packs (`Install-MtPack`, `maester-pack.json`) are new in Maester 3, which is in preview. Maester 2, the current
stable release, cannot install a pack. It runs **custom tests** instead: Pester test files in the `tests/Custom/`
folder of your Maester folder, which `Invoke-Maester` runs together with Maester's own tests. This zip has the
pack's tests in that form, so you get the same results on Maester 2.

This is a free community pack under the MIT licence, open to contributions from anyone. It is not a product of NSM,
the Maester project, Microsoft or any company, and it comes with no support agreement or warranty. Test titles and
results are in Norwegian, as in the Maester 3 pack.

## Install

1. Unpack the zip into `tests/Custom/` in your Maester folder, so that you get `tests/Custom/NSM/`.
   `Update-MaesterTests` does not change `Custom`.
2. Give the connection these Microsoft Graph permissions in addition to Maester's own:
   `AttackSimulation.Read.All`, `RoleManagementPolicy.Read.Directory` and `SecurityEvents.Read.All`.

```powershell
$scopes = (Get-MtGraphScope) + 'AttackSimulation.Read.All', 'RoleManagementPolicy.Read.Directory', 'SecurityEvents.Read.All'
Connect-MgGraph -Scopes $scopes
Invoke-Maester -Path ./tests -Tag NSM -SkipGraphConnect
```

App-only: give the app the 12 Graph permissions in `Uses.GraphScopes` of the pack's `maester-pack.json` as
application permissions.

## Settings

The tests read `GlobalSettings` in `maester-config.json`, as Maester 3 does:

- `EmergencyAccessAccounts`: the emergency access accounts, which Maester's own tests also use.
- `NsmGpIkt.MinimumWindowsBuild`, `NsmGpIkt.AllowedWindowsBuilds` and `NsmGpIkt.BaselinePolicyPattern`: see the
  pack's README.

## Differences from Maester 3

The full comparison is in `docs/maester-comparison.md` in the repository.

- The results are the same. Each result starts with the NSM verdict (høy, moderat or liten grad) and what it holds
  for.
- The report has no pack menu, guide or frameworks view.
- A test is skipped when the tenant lacks the licence it needs, as in Maester 3.
