"""Links from GP-IKT measures to NSM's own pages on nsm.no.

Each principle (1.1, 2.6, ...) has one page; its measures are rows in a table without anchors. A measure's link
is its principle page with a text fragment on the start of the measure's title, which Chrome, Edge, Safari and
Firefox scroll to and highlight; other browsers open the page at the top.
"""
from urllib.parse import quote

BASE = "https://nsm.no/regelverk-og-hjelp/rad-og-anbefalinger/"
OVERVIEW = BASE + "grunnprinsipper-for-ikt-sikkerhet/"
ALERT = "https://nsm.no/aktuelt/nsm-hever-det-nasjonale-cyberrisikonivaet-til-hoyt"

# Read from the overview page on 2026-11-03.
PRINCIPLE = {
    "1.1": "identifisere-og-kartlegge/kartlegg-styringsstrukturer-leveranser-og-understottende-systemer/",
    "1.2": "identifisere-og-kartlegge/kartlegg-enheter-og-programvare/",
    "1.3": "identifisere-og-kartlegge/kartlegg-brukere-og-behov-for-tilgang/",
    "2.1": "beskytte-og-opprettholde/ivareta-sikkerhet-i-anskaffelses-og-utviklingsprosesser/",
    "2.2": "beskytte-og-opprettholde/etabler-en-sikker-ikt-arkitektur/",
    "2.3": "beskytte-og-opprettholde/ivareta-en-sikker-konfigurasjon/",
    "2.4": "beskytte-og-opprettholde/beskytt-virksomhetens-nettverk/",
    "2.5": "beskytte-og-opprettholde/kontroller-dataflyt/",
    "2.6": "beskytte-og-opprettholde/ha-kontroll-pa-identiteter-og-tilganger/",
    "2.7": "beskytte-og-opprettholde/beskytt-data-i-ro-og-i-transitt/",
    "2.8": "beskytte-og-opprettholde/beskytt-e-post-og-nettleser/",
    "2.9": "beskytte-og-opprettholde/etabler-evne-til-gjenoppretting-av-data/",
    "2.10": "beskytte-og-opprettholde/integrer-sikkerhet-i-prosess-for-endringshandtering/",
    "3.1": "oppdage/oppdag-og-fjern-kjente-sarbarheter-og-trusler/",
    "3.2": "oppdage/etabler-sikkerhetsovervakning/",
    "3.3": "oppdage/analyser-data-fra-sikkerhetsovervakning/",
    "3.4": "oppdage/gjennomfor-inntrengningstester/",
    "4.1": "handtere-og-gjenopprette/forbered-virksomheten-pa-handtering-av-hendelser/",
    "4.2": "handtere-og-gjenopprette/vurder-og-klassifiser-hendelser/",
    "4.3": "handtere-og-gjenopprette/kontroller-og-handter-hendelser/",
    "4.4": "handtere-og-gjenopprette/evaluer-og-laer-av-hendelser/",
}


def principle_url(principle_id):
    return BASE + PRINCIPLE[principle_id]


def fragment_words(title):
    return " ".join(title.rstrip(".").split()[:5])


def measure_url(measure):
    """URL for a GP-IKT measure from gp-ikt-2.1.json (needs principle_id and title)."""
    # A hyphen marks a prefix or suffix in a text fragment, so it is encoded too.
    text = quote(fragment_words(measure["title"]), safe="").replace("-", "%2D")
    return principle_url(measure["principle_id"]) + "#:~:text=" + text
