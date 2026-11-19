"""Write the Maester framework files for the NSM pack from the GP-IKT catalogue and the alert additions, and the
links to NSM's own text in each test's documentation.

Usage: python3 tools/export_frameworks.py [pack-tests-folder]   (default: nsm-gp-ikt/tests in this repository)

Each Test.*.md gets generated links first under "#### Lenker", one per NSM measure the mapping catalogue
(tools/data/mapping.json) gives the test: the measure on nsm.no for GP-IKT, the alert for V1 to V7, each with the
strength of the link and the reason for it. Every list item whose text starts with "NSM" is replaced, so
edit the links here, not in the .md files, and do not start a hand-written link's text with "NSM".
"""
import json
import re
import sys
from pathlib import Path

HERE = Path(__file__).parent
sys.path.insert(0, str(HERE))
import nsm_links  # noqa: E402

GP = HERE / "data" / "gp-ikt-2.1.json"
ALERT = HERE / "data" / "nsm-alert-2026.json"
MAPPING = HERE / "data" / "mapping.json"
TESTS = HERE.parent / "nsm-gp-ikt" / "tests"
# The pack is Norwegian, so are the headings in each test's documentation. Maester does not parse them.
LINKS = "#### Lenker\n\n"


def write(path, obj):
    path.write_text(json.dumps(obj, ensure_ascii=False, indent=1) + "\n")
    print(f"{path}: {len(obj['Requirements'])} requirements")


def link_tests(tests, gp, extra):
    """Write the NSM links block into every test's .md, from the mapping catalogue (tools/data/mapping.json)."""
    mapping = json.loads(MAPPING.read_text())["tests"]
    kind = {"direkte": "Direkte kobling", "delvis": "Delvis kobling", "indikator": "Indikator, teller ikke som dekning"}
    for ps1 in sorted(tests.glob("Test.*.ps1")):
        md = ps1.with_suffix(".md")
        entry = mapping[re.search(r"(\d{4})", ps1.name).group(1)]
        lines = []
        for c in entry["cites"]:
            framework, rid = c["ref"].split(":", 1)
            clause = f" {c['clause']})" if c["clause"] else ""
            if framework == "nsm-gp-ikt":
                m = gp[rid]
                lines.append(f"- [NSM {rid}: {m['title'].rstrip('.')}]({nsm_links.measure_url(m)}) ({m['principle_id']} {m['principle']}). {kind[c['strength']]}{' til' + clause if clause else ''}: {c['why']}")
            else:
                lines.append(f"- [NSM-varselet, tiltak {rid}: {extra[rid]['title']}]({nsm_links.ALERT}). {kind[c['strength']]}: {c['why']}")
        # The NSM links are the list items whose text starts with "NSM", first under Lenker. No HTML comment
        # marks them: Maester's report shows comments as text. This also drops the general link to the overview page.
        text = re.sub(r"^(<!-- nsm-links:(start|end) -->|- \[NSM[ :-].*)\n", "", md.read_text(), flags=re.M)
        assert LINKS in text, f"{md.name} has no '{LINKS.strip()}' heading"
        text = text.replace(LINKS, LINKS + "\n".join(lines) + "\n", 1)
        md.write_text(text)
    print(f"{tests}: NSM links written")


def main():
    tests = Path(sys.argv[1]) if len(sys.argv) > 1 else TESTS
    out = tests / "frameworks"
    out.mkdir(parents=True, exist_ok=True)
    gp = json.loads(GP.read_text())
    alert = json.loads(ALERT.read_text())

    write(out / "nsm-gp-ikt.json", {
        "Framework": "nsm-gp-ikt",
        "Name": "NSMs grunnprinsipper for IKT-sikkerhet",
        "Version": "2.1",
        "Url": nsm_links.OVERVIEW,
        "Note": f"Generated from {gp['source']} ({gp['version']}). Identifiers and facts only, no NSM text: read each measure on nsm.no through its Url. Priority is NSM's priority group (1 is most important).",
        "Requirements": [{
            "Id": m["id"],
            "Principle": m["principle_id"],
            "Priority": m["priority"],
            "InAlert": m["in_alert"],
            "Url": nsm_links.measure_url(m),
        } for m in gp["measures"]],
    })
    write(out / "nsm-varsel-2026.json", {
        "Framework": "nsm-varsel-2026",
        "Name": "NSM-varsel om høyt cyberrisikonivå, tilleggstiltak",
        "Version": "2026-10-27",
        "Url": nsm_links.ALERT,
        "Note": f"Measures in NSM's alert of 27.10.2026 that have no GP-IKT number. NSM gives them no numbers or titles: V1 to V7 and their titles are the author's summary of the alert text, checked against nsm.no on {alert['checked']}.",
        "Requirements": [{"Id": v["id"], "Title": v["title"], "Group": v["group"], "Url": nsm_links.ALERT} for v in alert["extra"]],
    })
    link_tests(tests, {m["id"]: m for m in gp["measures"]}, {v["id"]: v for v in alert["extra"]})


if __name__ == "__main__":
    main()
