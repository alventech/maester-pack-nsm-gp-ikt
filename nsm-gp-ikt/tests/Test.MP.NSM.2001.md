Protokoller som bruker legacy authentication, som IMAP, POP og SMTP AUTH, støtter ikke MFA, og brukes mye i passordangrep. GP-IKT 2.3.3 i) ber om å deaktivere eldre eller ubrukte protokoller. Å blokkere dem er også en forutsetning for at MFA-kravet i 2.6.7 gjelder all pålogging.

- **Høy grad:** en aktivert policy blokkerer legacy authentication for alle brukere og apper med høyst to unntak, eller security defaults er på.
- **Moderat grad:** policyen står i report-only, gjelder bare noen, eller har flere unntak.
- **Liten grad:** ingen policy, og security defaults er av.

#### Remediation action

1. Sett policyen i report-only i et par uker, og se i påloggingsloggene (sign-in logs) hvem som fortsatt bruker legacy authentication.
2. Slå policyen på for alle brukere.

#### Lenker

- [NSM 2.3.3: Deaktiver unødvendig funksjonalitet](https://nsm.no/regelverk-og-hjelp/rad-og-anbefalinger/beskytte-og-opprettholde/ivareta-en-sikker-konfigurasjon/#:~:text=Deaktiver%20un%C3%B8dvendig%20funksjonalitet) (2.3 Ivareta en sikker konfigurasjon). Direkte kobling til i): 2.3.3 i) nevner eldre eller ubrukte protokoller. Legacy authentication bruker slike protokoller for pålogging.
- [NSM 2.6.7: Bruk multi-faktor autentisering](https://nsm.no/regelverk-og-hjelp/rad-og-anbefalinger/beskytte-og-opprettholde/ha-kontroll-pa-identiteter-og-tilganger/#:~:text=Bruk%20multi%2Dfaktor%20autentisering) (2.6 Ha kontroll på identiteter og tilganger). Delvis kobling til a): Legacy authentication kan ikke bruke MFA. Å blokkere den er en forutsetning for at MFA-kravet i 2.6.7 gjelder all pålogging.
- [Block legacy authentication](https://learn.microsoft.com/entra/identity/conditional-access/policy-block-legacy-authentication)

<!--- Results --->
%TestResult%
