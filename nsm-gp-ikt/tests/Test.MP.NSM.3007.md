GP-IKT 2.1.2 ber om moderne og oppdatert maskin- og programvare. Windows-versjoner uten støtte får ikke sikkerhetsoppdateringer. Sjekken sammenligner byggnummeret på hver forvaltet Windows-enhet med et minimum.

- **Høy grad:** alle enheter har minst minimumsbygget.
- **Moderat grad:** minst 90 %.
- **Liten grad:** færre.

Minimum er 26100 (Windows 11 24H2) som standard. Windows 10 og Windows 11 23H2 (22631) er ute av ordinær støtte. Endre minimum med innstillingen `NsmGpIkt.MinimumWindowsBuild` i maester-config.json. Bygg under minimum som virksomheten har støtte for, som Windows LTSC (for eksempel 17763 eller 19044), legges i `NsmGpIkt.AllowedWindowsBuilds`. En versjon som ikke kan leses, telles som uten støtte.

#### Remediation action

1. Oppgrader enheter med eldre bygg med en feature update-policy i Intune.
2. Bytt ut maskinvare som ikke kan kjøre Windows 11.

#### Lenker

- [NSM 2.1.2: Kjøp moderne og oppdatert maskin- og programvare](https://nsm.no/regelverk-og-hjelp/rad-og-anbefalinger/beskytte-og-opprettholde/ivareta-sikkerhet-i-anskaffelses-og-utviklingsprosesser/#:~:text=Kj%C3%B8p%20moderne%20og%20oppdatert%20maskin%2D) (2.1 Ivareta sikkerhet i anskaffelses- og utviklingsprosesser). Delvis kobling til a): 2.1.2 ber om moderne og oppdatert maskin- og programvare. En Windows-versjon med støtte er en del av det for klientene.
- [Windows release health](https://learn.microsoft.com/windows/release-health/windows11-release-information)

<!--- Results --->
%TestResult%
