Phishing-resistent MFA forutsetter at passkeys (FIDO2) er tillatt, og at de svakeste metodene ikke kan brukes som reserve. Policyen er en forutsetning for kravet i NSM-varselet (V1), ikke kravet selv: koblingen er delvis. Sjekken leser Authentication methods-policyen i Entra.

- **Høy grad:** FIDO2 er aktivert med attestation, SMS, tale og Email OTP er av, og migreringen fra legacy MFA- og SSPR-policyene er fullført.
- **Moderat grad:** FIDO2 er aktivert, men SMS, tale eller Email OTP er fortsatt på, attestation er ikke påkrevd, eller migreringen er ikke fullført, slik at legacy-policyene fortsatt kan tillate SMS og tale.
- **Liten grad:** FIDO2 er av.

Email OTP her er metoden for virksomhetens egne brukere, som lar dem tilbakestille passordet med en kode på e-post. Email OTP for gjester er en egen innstilling under External Identities og telles ikke.

#### Remediation action

1. Aktiver passkey (FIDO2) for alle brukere, og krev attestation.
2. Slå av SMS, taleanrop og Email OTP når brukerne har en sterkere metode. Gjestenes Email OTP påvirkes ikke.

#### Lenker

- [NSM-varselet, tiltak V1: Bruk phishing-resistent multifaktorautentisering](https://nsm.no/aktuelt/nsm-hever-det-nasjonale-cyberrisikonivaet-til-hoyt). Delvis kobling: Policyen gjør phishing-resistente metoder tilgjengelige og slår av de svakeste. Den er en forutsetning for kravet, ikke kravet selv.
- [Manage authentication methods](https://learn.microsoft.com/entra/identity/authentication/concept-authentication-methods-manage)

<!--- Results --->
%TestResult%
