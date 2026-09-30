"""Egzersiz veri setini uygulama varlığına indirger.

Kaynak: github.com/hasaneyldrm/exercises-dataset (veri MIT; görsel/GIF © Gym visual).
Medya dosyaları pakete GÖMÜLMEZ; uygulama bunları GitHub'dan isteğe bağlı çeker ve önbellekler.
Çıktı: app/assets/data/exercises.json (yalnızca Türkçe+İngilizce adımlar, ~2-3 MB)

Kullanım: python tools/build_exercise_assets.py [exercises.json yolu]
"""
import json
import sys
import urllib.request
from pathlib import Path

URL = "https://raw.githubusercontent.com/hasaneyldrm/exercises-dataset/main/data/exercises.json"
OUT = Path(__file__).resolve().parent.parent / "app/assets/data/exercises.json"


def main():
    if len(sys.argv) > 1:
        raw = json.loads(Path(sys.argv[1]).read_text(encoding="utf-8"))
    else:
        raw = json.loads(urllib.request.urlopen(URL, timeout=120).read().decode("utf-8"))
    out = []
    for e in raw:
        steps = e.get("instruction_steps", {})
        out.append({
            "id": e["id"],
            "name": e["name"],
            "bodyPart": e["body_part"],
            "equipment": e["equipment"],
            "target": e["target"],
            "muscle": e.get("muscle_group", ""),
            "secondary": e.get("secondary_muscles", []),
            "stepsTr": [s.replace("​", "") for s in steps.get("tr", [])],
            "stepsEn": steps.get("en", []),
            "image": e["image"],
            "gif": e["gif_url"],
        })
    OUT.parent.mkdir(parents=True, exist_ok=True)
    OUT.write_text(json.dumps(out, ensure_ascii=False, separators=(",", ":")), encoding="utf-8")
    print(f"{len(out)} egzersiz -> {OUT} ({OUT.stat().st_size/1024:.0f} KB)")


if __name__ == "__main__":
    main()
