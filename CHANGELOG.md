# Changelog

## 0.3.0

The first public release: a free community pack under the MIT licence.

- **28 tests** of NSM's ICT Security Principles 2.1 (GP-IKT) and the measures in NSM's alert of 27.10.2026, read
  from Microsoft Graph: Entra ID, Microsoft 365, Defender and Intune. Read only; the pack never writes to a tenant.
- **NSM's scale.** Every result starts with *NSM-vurdering: Høy | Moderat | Liten grad*; only *høy grad* passes.
  The second line, *Gjelder*, says what the verdict holds for, so it cannot be read as covering the whole measure.
- **Every link to NSM has a clause, a strength (direct, partial, indicator) and a scope**, kept in
  `tools/data/mapping.json`; see [docs/mapping.md](https://github.com/alventech/maester-pack-nsm-gp-ikt/blob/main/docs/mapping.md) and [docs/coverage.md](https://github.com/alventech/maester-pack-nsm-gp-ikt/blob/main/docs/coverage.md).
- **Skips, not guesses.** A test skips with a reason when the tenant lacks its licence or the connection lacks a
  permission; neither gives *liten grad*.
- **Maester 3:** the pack's own menu, a guide (prerequisites, connect, run, settings), the frameworks view for
  GP-IKT 2.1 and the alert, and ATT&CK techniques on 17 tests, copied from the Maester test that reads the same
  setting.
- **Maester 2.x:** the same tests as custom tests in `nsm-gp-ikt-maester2-0.3.0.zip`, with the same results.
- **Settings** in `maester-config.json`: `EmergencyAccessAccounts`, `NsmGpIkt.MinimumWindowsBuild`,
  `NsmGpIkt.AllowedWindowsBuilds` and `NsmGpIkt.BaselinePolicyPattern`.
- How the pack differs from Maester's own tests: [docs/maester-comparison.md](https://github.com/alventech/maester-pack-nsm-gp-ikt/blob/main/docs/maester-comparison.md).
