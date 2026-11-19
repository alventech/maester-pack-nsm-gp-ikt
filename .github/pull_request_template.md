## What and why

<!-- A changed level: the test ID, the old and new level, and the reason (NSM's text, Microsoft's documentation). -->

## Checklist

- [ ] `Invoke-Pester ./unit-tests` passes; a changed verdict has a unit test that fails without the change
- [ ] `Test-MtPack ./nsm-gp-ikt` is valid, Low risk, no warnings
- [ ] Changed a test's `Control`, title or levels, or NSM's data? Regenerate the docs (Python 3, no packages):
      `python3 tools/export_frameworks.py && python3 tools/generate_docs.py` (macOS, Linux),
      `py tools\export_frameworks.py; py tools\generate_docs.py` (Windows). CI checks it and prints the commands.
- [ ] A line in `CHANGELOG.md` for anything a user notices
- [ ] Kinds of tenant run (profiles in docs/verification.md; no names, domains or IDs), if any:
- [ ] No tenant data (IDs, domains, names, reports) in the pull request
