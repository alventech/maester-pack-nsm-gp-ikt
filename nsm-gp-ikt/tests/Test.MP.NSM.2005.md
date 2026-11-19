GP-IKT 2.8.4 sier: tillat kun virksomhetsgodkjente programtillegg. Tillegg i e-postleseren får tilgang til innholdet i postboksen. Sjekken leser Secure Score-anbefalingen om at brukere ikke skal kunne installere Outlook-tillegg selv, med Microsofts egen status for tenanten.

- **Høy grad:** anbefalingen er fullt oppfylt: brukere kan ikke installere tillegg selv.
- **Moderat grad:** delvis oppfylt: noen brukere kan.
- **Liten grad:** ikke oppfylt.

Vurderingen gjelder Outlook i Exchange Online. Nettlesertillegg og tillegg i andre Office-programmer måles ikke.

#### Remediation action

1. Fjern rollene *My Custom Apps*, *My Marketplace Apps* og *My ReadWriteMailbox Apps* fra role assignment policies i Exchange Online.
2. Rull ut tilleggene virksomheten har godkjent, sentralt fra **Microsoft 365 admin center > Integrated apps**.

#### Lenker

- [NSM 2.8.4: Tillat kun virksomhetsgodkjente programtillegg](https://nsm.no/regelverk-og-hjelp/rad-og-anbefalinger/beskytte-og-opprettholde/beskytt-e-post-og-nettleser/#:~:text=Tillat%20kun%20virksomhetsgodkjente%20programtillegg) (2.8 Beskytt e-post og nettleser). Direkte kobling: 2.8.4 sier: tillat kun virksomhetsgodkjente programtillegg, og nevner e-postleseren. Når brukere ikke kan installere Outlook-tillegg selv, er det bare de virksomheten ruller ut som kjører. Nettlesertillegg måles ikke.
- [Specify the administrators and users who can install and manage add-ins for Outlook](https://learn.microsoft.com/exchange/clients-and-mobile-in-exchange-online/add-ins-for-outlook/specify-who-can-install-and-manage-add-ins)

<!--- Results --->
%TestResult%
