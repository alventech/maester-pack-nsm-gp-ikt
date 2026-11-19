# Permissions

The pack only reads. `Uses.TenantWrites` in `maester-pack.json` is empty, every Microsoft Graph permission it asks
for is a `.Read.` permission, and every request it makes is a GET. It cannot change a setting, a policy or an
account.

**Read-only is not the same as low risk.** Together, the 12 permissions let the identity that runs the pack read
the tenant's whole security configuration: every Conditional Access policy and its exclusions, who holds which
privileged role, which accounts lack phishing-resistant MFA, which devices are unencrypted, and how Secure Score
rates the tenant. That is a map an attacker would want before an attack. Treat the identity, and the reports it
produces, as sensitive; see [securing the identity that runs the pack](#securing-the-identity-that-runs-the-pack).

## What each permission reads

| Permission | Tests | What the pack reads with it |
| --- | --- | --- |
| `Policy.Read.All` | 1001–1005, 1009, 1011, 1012, 2001, 3001 | Conditional Access policies, authentication strengths, the authentication methods policy, the authorisation policy (user consent) and the device settings in Entra ID (`policies/deviceRegistrationPolicy`) |
| `Directory.Read.All` | 1003, 1006, 1008, 2004, 3001 | Users (enabled members and guests), the names of who holds a role (`$expand=principal`), and whether the tenant syncs from on-premises AD (`organization`) |
| `AuditLog.Read.All` | 1002, 1003 | The authentication methods registration report (who has registered which method). The pack does not read sign-in or audit logs |
| `RoleManagement.Read.Directory` | 1006, 1007 | Directory role assignments and PIM eligibility |
| `RoleManagementPolicy.Read.Directory` | 1007 | PIM activation rules (approval, MFA, authentication context) for Global Administrator |
| `AccessReview.Read.All` | 1008 | Access review definitions for guests |
| `AttackSimulation.Read.All` | 2003 | Attack simulation training runs |
| `SecurityEvents.Read.All` | 2002, 2004, 2005 | Microsoft Secure Score and its control scores |
| `DirectoryRecommendations.Read.All` | 1010 | Entra recommendations |
| `Device.Read.All` | 3006 | Devices in Entra ID |
| `DeviceManagementConfiguration.Read.All` | 3001–3004, 3008–3011 | Intune policies (settings catalog, endpoint security, update rings, compliance) and their assignments |
| `DeviceManagementManagedDevices.Read.All` | 3002, 3005, 3007, 3011 | Intune managed devices: OS version, encryption, compliance, last check-in |

**Graph beta.** Some reads exist only in Microsoft Graph's beta version, which Microsoft can change without
notice: Intune's settings catalog, endpoint security, intents, templates and device configurations (3001–3004,
3008–3011) and Entra recommendations (1010). Every other read uses v1.0. CI cannot catch a beta change, because it
never connects to a tenant; it shows up when the pack runs against a tenant. Report it as a bug.

The permissions each test needs are also in its `Permission` attribute and in [tests.md](tests.md). A test whose
permission is missing skips as *NotAuthorized*; it never gives a level.

### Why the broad ones

- **`Directory.Read.All`**: role assignments name their holders only when the principal is expanded, which needs
  directory read. Narrower scopes (`User.Read.All`, `Group.Read.All`) do not cover every principal type.
- **`Policy.Read.All`**: the only application permission that reads Conditional Access, authentication methods and
  authorisation policies together. If Graph refuses `policies/deviceRegistrationPolicy` with it in your tenant
  (1011, 3001 skip as not authorised), add `Policy.Read.DeviceConfiguration`.
- **`SecurityEvents.Read.All`**: Secure Score is only exposed through this scope.
- **`Device.Read.All` and `RoleManagement.Read.Directory`** are in the manifest so that an app-only identity can run
  every test; for a signed-in admin, Maester's `Directory.Read.All` and `RoleManagement.Read.All` already cover
  them.

## Delegated: an admin signs in

`Connect-Maester` asks for Maester's own scopes (`Get-MtGraphScope`). Three of the pack's scopes are not among
them, so add them:

```powershell
$scopes = (Get-MtGraphScope) + 'AttackSimulation.Read.All', 'RoleManagementPolicy.Read.Directory', 'SecurityEvents.Read.All'
Connect-MgGraph -Scopes $scopes
Invoke-Maester -Pack NSM -SkipBuiltIn -SkipGraphConnect
```

A delegated permission only reaches what the signed-in account can see, so the account also needs a role.
**Global Reader** can read all of it. The authentication methods registration report (1002, 1003) needs Global
Reader, Reports Reader, Security Reader or a higher role. The first sign-in with new scopes needs admin consent.

Sign in in the browser. Do not use `-UseDeviceCode`: device code sign-in is a known phishing route and is often
blocked by Conditional Access.

## App-only: unattended runs

1. Register an app in Entra ID for Maester only, or use a managed identity. Do not reuse an app that has other
   permissions.
2. Grant the 12 scopes in `Uses.GraphScopes` of `maester-pack.json` as **application** permissions for Microsoft
   Graph, and grant admin consent. Grant nothing else.
3. Use a credential that cannot be copied as text: a managed identity (Azure), workload identity federation (a
   pipeline in GitHub Actions or Azure DevOps), or a certificate kept in a key vault. Avoid client secrets.
4. Connect and run:

```powershell
Connect-MgGraph -TenantId <tenant-id> -ClientId <app-id> -CertificateThumbprint <thumbprint> -NoWelcome
Invoke-Maester -Pack NSM -SkipBuiltIn -SkipGraphConnect -NonInteractive
```

An application permission applies to the whole tenant: no role or scope limits it. That is why the next section
matters most for app-only runs.

## Securing the identity that runs the pack

The identity holds standing, tenant-wide read access to security configuration, and it cannot do multi-factor
authentication. Monitor it like an administrator account.

**Reduce what it can do**
- One identity for Maester, with exactly the permissions above, no directory role, and no owners other than the
  administrators who manage it.
- A managed identity or workload identity federation where possible: there is no credential to steal. Otherwise a
  certificate with a short lifetime, stored in a key vault, rotated before it expires.
- Remove the identity, or its permissions, when you stop running the pack.

**Watch what it does**
- **Service principal sign-ins** (Entra admin center > Entra ID > Monitoring & health > Sign-in logs > Service
  principal sign-ins): it should sign in only from where Maester runs, and only when a run is scheduled.
- **Audit logs**: alert on new credentials for the app ("Add service principal credentials", "Update application –
  Certificates and secrets management"), new app role assignments and owner changes. These are how a read-only app
  is turned into something more.
- **Microsoft Graph activity logs**, sent to Log Analytics or a SIEM, show every request the identity makes. Read
  requests outside the pack's endpoints are worth a look.
- Review the identity's permissions on a schedule, for example in an access review.

**Restrict where it can sign in** (needs Microsoft Entra Workload ID Premium)
- A Conditional Access policy for workload identities can block the app from outside known IP ranges, and block it
  when ID Protection marks it risky. These policies apply to single-tenant apps you register, not to managed
  identities. See Microsoft's [Conditional Access for workload identities](https://learn.microsoft.com/entra/identity/conditional-access/workload-identity)
  and [securing workload identities](https://learn.microsoft.com/entra/id-protection/concept-workload-identity-risk).

**Protect the results**
- The reports name policies, roles, privileged accounts and unencrypted devices. Store them where only the people
  who act on them can read them, and never attach them to a public issue.
