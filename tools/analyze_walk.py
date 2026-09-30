"""walktest JSONL çözümleyici: adım sayacı, nabız akışı, pil.

Kullanım: python tools/analyze_walk.py [dosya.jsonl]   (verilmezse en yenisi)
Çözümleme kuralları (Veepoo SDK'dan):
  a8: bayt1-4 büyük-uçlu adım sayısı (FFFFFFFF = 0)
  d0: bayt1 = bpm (30..210 geçerli; 1,2 = bant takılı değil), bayt5 = durum (0,2,3 iyi)
  a0: pil cevabı (ham gösterilir)
"""
import json
import statistics
import sys
from pathlib import Path


def load(path):
    rows = []
    for line in Path(path).read_text(encoding="utf-8").splitlines():
        r = json.loads(line)
        r["b"] = bytes.fromhex(r["hex"])
        rows.append(r)
    return rows


def parse_steps(b):
    v = int.from_bytes(b[1:5], "big")
    return 0 if v == 0xFFFFFFFF else v


def parse_hr(b):
    bpm, status = b[1], b[5]
    if bpm in (1, 2):
        return None, "takili_degil"
    if not (30 <= bpm <= 210):
        return None, "gecersiz"
    return bpm, ("iyi" if status in (0, 2, 3) else "mesgul")


def analyze(path):
    rows = [r for r in load(path) if r["k"] == "rx"]
    steps = [(r["t"], parse_steps(r["b"])) for r in rows if r["b"][0] == 0xA8]
    hr_all = [(r["t"], *parse_hr(r["b"])) for r in rows if r["b"][0] == 0xD0]
    hr = [(t, bpm) for t, bpm, st in hr_all if bpm is not None]
    bat = [r["b"].hex() for r in rows if r["b"][0] == 0xA0]
    out = {"dosya": str(path), "sure_sn": rows[-1]["t"] if rows else 0}
    if steps:
        out["adim_ilk"], out["adim_son"] = steps[0][1], steps[-1][1]
        out["adim_fark"] = steps[-1][1] - steps[0][1]
    out["nabiz_cevap_sayisi"] = len(hr_all)
    out["nabiz_gecerli_sayisi"] = len(hr)
    durumlar = {}
    for _, bpm, st in hr_all:
        durumlar[st] = durumlar.get(st, 0) + 1
    out["nabiz_durumlar"] = durumlar
    if hr:
        vals = [v for _, v in hr]
        gaps = [b[0] - a[0] for a, b in zip(hr, hr[1:])]
        out["nabiz_min_max_ort"] = (min(vals), max(vals), round(statistics.mean(vals), 1))
        if gaps:
            out["nabiz_aralik_sn_medyan"] = round(statistics.median(gaps), 2)
    out["pil_ham"] = bat[:2]
    return out, steps, hr


def timeline(steps, hr, bucket=15):
    print("\nzaman(sn) | adım(sayaç) | adım artışı | nabız(ort)")
    end = int(max([t for t, _ in steps] + [t for t, _ in hr] + [0])) + 1
    prev = None
    for a in range(0, end, bucket):
        s = [v for t, v in steps if a <= t < a + bucket]
        h = [v for t, v in hr if a <= t < a + bucket]
        if not s and not h:
            continue
        cur = s[-1] if s else prev
        delta = (cur - prev) if (cur is not None and prev is not None) else 0
        print(f"{a:>4}-{a + bucket:<4} | {cur if cur is not None else '-':>10} | {delta:>10} | "
              f"{round(statistics.mean(h)) if h else '-':>5}")
        prev = cur if cur is not None else prev


if __name__ == "__main__":
    p = sys.argv[1] if len(sys.argv) > 1 else sorted(
        (Path(__file__).resolve().parent.parent / "data").glob("walktest_*.jsonl"))[-1]
    summary, steps, hr = analyze(p)
    for k, v in summary.items():
        print(f"{k}: {v}")
    timeline(steps, hr)
