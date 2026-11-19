# Security

The pack reads Microsoft Graph with read-only permissions and never writes to a tenant. It reaches no other
service and loads no modules (`Uses` in `maester-pack.json`).

## Reporting a vulnerability

Do not open a public issue. Report it privately through the repository's GitHub security advisories
("Report a vulnerability"). Include the pack version and what an attacker could do.

A malicious or compromised release of any pack can also be reported to the Maester maintainers through Maester's
GitHub security advisories, so it can be added to Maester's blocklist.

## Data in results

Results and reports contain names of policies, roles, accounts and devices from the tenant that was tested. Do not
attach them to public issues; describe the tenant's setup instead.
