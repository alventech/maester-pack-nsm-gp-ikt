"""Extract NSM Grunnprinsipper for IKT-sikkerhet 2.1 from NSM's spreadsheet into gp-ikt-2.1.json.

Usage: python3 tools/extract_gp.py <NSM spreadsheet.xlsx>   (needs openpyxl)

The spreadsheet is "Regneark med tiltak fra NSMs grunnprinsipper for IKT-sikkerhet.xlsx" from nsm.no. It is not
kept in this repository; the output, data/gp-ikt-2.1.json, is.
"""
import json
import sys
from pathlib import Path

import openpyxl

HERE = Path(__file__).parent
OUT = HERE / "data" / "gp-ikt-2.1.json"

# The GP-IKT measures NSM lists under "Øvrige tiltak" in the alert of 27.10.2026, kept in data/nsm-alert-2026.json.
ALERT = set(json.loads((HERE / "data" / "nsm-alert-2026.json").read_text())["measures"])


def main():
    src = Path(sys.argv[1])
    ws = openpyxl.load_workbook(src, data_only=True)["01 NSM GP-IKT 2.1"]
    measures = []
    for r in ws.iter_rows(min_row=4, values_only=True):
        if not (r[5] and r[6]):
            continue
        measures.append({
            "id": str(r[5]).strip(),
            "category": str(r[1]).strip(),
            "principle_id": str(r[2]).strip(),
            "principle": str(r[3]).strip(),
            "title": str(r[6]).strip(),
            "description": str(r[7] or "").strip(),
            "priority": int(r[8]),
            "iso27002": [str(v).strip() for v in r[9:] if v not in (None, "")],
            "in_alert": str(r[5]).strip() in ALERT,
        })
    missing = ALERT - {m["id"] for m in measures}
    assert not missing, f"alert measures not found: {missing}"
    OUT.write_text(json.dumps({
        "source": src.name,
        "version": "GP-IKT 2.1 (regneark sist endret 2026-04)",
        "measures": measures,
    }, ensure_ascii=False, indent=1))
    print(f"{len(measures)} measures -> {OUT.name}")


if __name__ == "__main__":
    main()
