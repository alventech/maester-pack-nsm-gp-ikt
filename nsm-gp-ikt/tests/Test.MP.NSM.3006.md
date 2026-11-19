GP-IKT 1.2.3 er et prioritet 1-tiltak: kartlegg enhetene i bruk. Enheter som er registrert i Entra ID, men ikke forvaltet, får verken herding eller oppdateringer. Sjekken sammenligner aktive Windows-enheter i Entra ID med dem som er forvaltet. Koblingen er delvis: 1.2.3 gjelder alle enheter med IP-adresse, også mobile enheter, servere, nettverksutstyr og skrivere, som sjekken ikke ser.

- **Høy grad:** minst 95 % er forvaltet.
- **Moderat grad:** minst 80 %.
- **Liten grad:** lavere.

Enheter som ikke er registrert i Entra ID i det hele tatt, synes ikke her. De finnes med device discovery i Defender for Endpoint.

#### Remediation action

1. Registrer (enroll) uforvaltede enheter i Intune, eller fjern dem.
2. Slå på device discovery i Defender for Endpoint for å finne enheter som ikke er registrert.

#### Lenker

- [NSM 1.2.3: Kartlegg enheter i bruk i virksomheten](https://nsm.no/regelverk-og-hjelp/rad-og-anbefalinger/identifisere-og-kartlegge/kartlegg-enheter-og-programvare/#:~:text=Kartlegg%20enheter%20i%20bruk%20i) (1.2 Kartlegg enheter og programvare). Delvis kobling til a): 1.2.3 a) ber om oversikt over enhetene, blant annet om de er forvaltet av virksomheten. Sjekken dekker Windows-enheter som logger på Entra ID, ikke mobile enheter, servere, nettverksutstyr eller skrivere.
- [Device discovery in Defender for Endpoint](https://learn.microsoft.com/defender-endpoint/device-discovery)

<!--- Results --->
%TestResult%
