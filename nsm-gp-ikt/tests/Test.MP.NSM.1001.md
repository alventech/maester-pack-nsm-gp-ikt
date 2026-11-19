NSM ber virksomheter bruke phishing-resistent multifaktorautentisering (varselet 27.10.2026, tiltak V1). GP-IKT 2.6.7 godtar også engangspassord og måles av MP.NSM.1005. Sjekken leser Conditional Access-policyene og ser etter authentication strengths som bare tillater FIDO2/passkeys, Windows Hello for Business eller certificate-based authentication (CBA).

Unntak er ekskluderte brukere, grupper, roller, gjester og apper. Begrensende vilkår er locations, device platforms, client apps, risk og filter for devices: en policy som bare gjelder utenfor kjente nettverk, gjelder ikke alle.

- **Høy grad:** en aktivert policy krever en slik authentication strength for alle brukere og alle apper, med høyst to unntak utover nødtilgangskontoene, uten vilkår som begrenser den, og uten en annen kontroll som kan oppfylle den i stedet.
- **Moderat grad:** bare for noen brukere, apper eller situasjoner, med flere unntak, eller policyen for alle står i report-only.
- **Liten grad:** ingen policy.

#### Remediation action

1. Rull ut passkeys (FIDO2 eller Microsoft Authenticator) og Windows Hello for Business.
2. Lag en policy som krever den innebygde authentication strength «Phishing-resistant MFA» for administratorroller først.
3. Utvid til alle brukere og alle apper, med unntak bare for nødtilgangskontoer.

#### Lenker

- [NSM-varselet, tiltak V1: Bruk phishing-resistent multifaktorautentisering](https://nsm.no/aktuelt/nsm-hever-det-nasjonale-cyberrisikonivaet-til-hoyt). Direkte kobling: Varselet ber om phishing-resistent MFA. En Conditional Access-policy med phishing-resistent authentication strength er kravet håndhevet ved pålogging.
- [Authentication strengths in Conditional Access](https://learn.microsoft.com/entra/identity/authentication/concept-authentication-strengths)

<!--- Results --->
%TestResult%
