GP-IKT 2.7.3 ber om å kryptere lagringsmedier som lett kan mistes, som mobile klienter. Sjekken teller Windows-enhetene Intune melder som kryptert.

- **Høy grad:** minst 95 % er kryptert.
- **Moderat grad:** minst 80 %.
- **Liten grad:** lavere.

Enheter som ikke er kryptert, er listet i resultatet. Vurderingen gjelder Windows-klienter i Intune, ikke mobiltelefoner, Mac eller flyttbare medier.

#### Remediation action

1. Lag en BitLocker-policy under **Endpoint security > Disk encryption** og tildel den alle Windows-enheter.
2. Krev kryptering i compliance policyen, slik at en ukryptert enhet får en konsekvens.

#### Lenker

- [NSM 2.7.3: Krypter lagringsmedier som holder konfidensiell data og som lett kan mistes eller kompromitteres](https://nsm.no/regelverk-og-hjelp/rad-og-anbefalinger/beskytte-og-opprettholde/beskytt-data-i-ro-og-i-transitt/#:~:text=Krypter%20lagringsmedier%20som%20holder%20konfidensiell) (2.7 Beskytt data i ro og i transitt). Direkte kobling: 2.7.3 ber om å kryptere lagringsmedier som lett kan mistes, som mobile klienter. Sjekken teller enhetene Intune melder som kryptert.
- [Encrypt Windows devices with BitLocker in Intune](https://learn.microsoft.com/intune/intune-service/protect/encrypt-devices)

<!--- Results --->
%TestResult%
