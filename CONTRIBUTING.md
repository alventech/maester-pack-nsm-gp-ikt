# Contributing

This is a free community pack. Anyone can open an issue or a pull request: a new test, a fix, a better reading of
NSM's text, or results from a kind of tenant the pack has not been run in.

## Disagreeing with a level

People will disagree with where a test draws the line between *høy*, *moderat* and *liten grad*. That is expected:
the levels are a reading of NSM's text, written down in each test's `.md` and in [docs/mapping.md](docs/mapping.md).

1. Open a **Wrong verdict** issue: the test ID, the tenant profile (the kind of tenant from
   [docs/verification.md](docs/verification.md), such as "Business Premium, cloud-only"; never its name, domain or
   IDs), what the portal shows, and the level you think is right and why.
2. The maintainer decides after the discussion, from NSM's text and Microsoft's documentation, and writes the
   reason in the issue. Agreement is welcome but not required; the reason is.
3. If the rule changes, the pull request changes the test, its `.md` and a unit test that shows the new level, and
   adds a line to the changelog. The level changes for everyone, so the reason is written down.

Never attach reports or screenshots with your tenant's data to a public issue; describe the setup instead.


## Rules for tests

- **Test IDs are permanent.** `MP.NSM.<n>` is never renumbered or reused. A retired test keeps its ID out of use.
- **`Control` is the only mapping to NSM.** Follow the rules in [docs/mapping.md](docs/mapping.md): specify the
  measure the check proves, primary first, and say so in the `.md` when it is an interpretation. Add a line to the
  changes table there when a mapping changes.
- **Every result starts with the level.** End a test with `Complete-MtNsmResult -Level H|M|L`. Only `H` passes.
- **Skip, don't guess.** When the test cannot measure (missing licence, permission, product or data), skip with
  `Add-MtTestResultDetail -SkippedBecause <reason>`. Never score *liten grad* because a call failed. Declare the
  licence with the `License` attribute rather than checking it in code, and catch only the errors you expect.
- **Read only.** No request may change the tenant.
- **Norwegian test texts, English code and docs.** Keep NSM's own terms (*høy grad*, *tiltak*).
- **No NSM text in the framework files.** IDs and facts only.

## Before a pull request

```powershell
Invoke-Pester ./unit-tests          # every level and skip, with mocked Graph responses
Test-MtPack ./nsm-gp-ikt
./scripts/Invoke-NsmPackSmokeTest.ps1 -SkipConnect
```

A fix for a wrong verdict comes with a unit test that fails without the fix.

```bash
python3 tools/export_frameworks.py && python3 tools/generate_docs.py && git status --short
```

Say in the pull request which tenant profiles from [docs/verification.md](docs/verification.md) you ran it in.

## A new version of NSM's principles

1. Download NSM's spreadsheet from nsm.no.
2. `python3 tools/extract_gp.py <spreadsheet.xlsx>` (needs `openpyxl`), then compare `tools/data/gp-ikt-2.1.json`.
3. Check every test's `Control` against the new text, update `tools/nsm_links.py` if NSM moved pages, and regenerate.
4. A new GP-IKT version is a new framework version: update `Version` in `suite.json` and the framework file.
