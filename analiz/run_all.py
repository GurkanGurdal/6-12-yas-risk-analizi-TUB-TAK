"""
Tum 6 analizi sirayla calistirir, sonra RAPOR.md uretir.

Kullanim:
    python analiz/run_all.py            # tum analizleri ve raporu yazar
    python analiz/run_all.py --rapor    # sadece RAPOR.md uretir (analizleri tekrar calistirma)
"""
from __future__ import annotations

import json
import subprocess
import sys
import time
from pathlib import Path

ANALIZ_DIR = Path(__file__).resolve().parent
SONUC_DIR = ANALIZ_DIR / "sonuclar"

ADIMLAR = [
    ("01_temporal_validasyon.py", "Temporal Validasyon"),
    ("02_bootstrap_ci.py",        "Bootstrap %95 CI"),
    ("03_kalibrasyon.py",         "Kalibrasyon"),
    ("04_shap_analizi.py",        "SHAP Analizi"),
    ("07_agirlik_turetme.py",     "Agirlik Veriden Turetme"),
    ("05_agirlik_sensitivity.py", "Agirlik Duyarlilik"),
    ("06_birlesik_skor_dogrulama.py", "Birlesik Skor Dis Dogrulamasi"),
]


def calistir() -> None:
    t0 = time.time()
    for dosya, ad in ADIMLAR:
        print(f"\n{'#' * 70}")
        print(f"# {ad} ({dosya})")
        print(f"{'#' * 70}")
        r = subprocess.run([sys.executable, str(ANALIZ_DIR / dosya)])
        if r.returncode != 0:
            print(f"\n!!! HATA: {dosya} basarisiz oldu (exit {r.returncode})")
            sys.exit(r.returncode)
    print(f"\nTum analizler tamam: {time.time() - t0:.1f}s")


def _yukle(p: Path) -> dict | None:
    if not p.exists():
        return None
    with open(p, 'r', encoding='utf-8') as f:
        return json.load(f)


def rapor_uret() -> None:
    print("\n=== RAPOR.md uretiliyor ===")
    temporal = _yukle(SONUC_DIR / "01_temporal_metrikler.json")
    bootstrap = _yukle(SONUC_DIR / "02_bootstrap_ci.json")
    kalibrasyon = _yukle(SONUC_DIR / "03_kalibrasyon.json")
    shap_top = _yukle(SONUC_DIR / "04_shap" / "top_features.json")
    sensitivity = _yukle(SONUC_DIR / "05_sensitivity.json")
    spearman = _yukle(SONUC_DIR / "06_spearman.json")
    agirlik = _yukle(SONUC_DIR / "07_agirlik_turetme.json")

    if not all([temporal, bootstrap, kalibrasyon, shap_top, sensitivity, spearman, agirlik]):
        print("Eksik JSON dosyalari var, bazi bolumler atlanacak.")

    lines: list[str] = []
    lines.append("# Makale Oncesi Analizler — Sonuc Raporu")
    lines.append("")
    lines.append("Bu rapor 6 analiz scriptinin ciktisindan otomatik uretilmistir.")
    lines.append("Detaylar icin `analiz/sonuclar/` altindaki JSON dosyalarina ve PNG figurlere bakin.")
    lines.append("")

    # ----- Tablo 1 + Bootstrap CI birlesik -----
    lines.append("## Tablo 1 — Temporal Validasyon Performansi (%95 Bootstrap CI)")
    lines.append("")
    lines.append("Egitim: NSCH 2022 | Test: NSCH 2023 (held-out yil)")
    lines.append("")
    lines.append("| Model | n_test | AUC | F1 | Recall | Precision |")
    lines.append("|-------|-------:|-----|----|--------|-----------|")
    if temporal and bootstrap:
        for ad, t in temporal.items():
            b = bootstrap.get(ad, {})
            def fmt(metric_dict, key):
                m = b.get(key, {})
                if not m:
                    return f"{t.get(key, 0):.3f}"
                return f"{m['mean']:.3f} ({m['lower']:.3f}–{m['upper']:.3f})"
            lines.append(f"| {ad} | {t['n_test_2023']} | "
                         f"{fmt(b, 'auc')} | {fmt(b, 'f1')} | "
                         f"{fmt(b, 'recall')} | {fmt(b, 'precision')} |")
    lines.append("")
    if temporal:
        lines.append("**Random-split (eski yontemle) vs Temporal (yeni) AUC karsilastirmasi:**")
        lines.append("")
        lines.append("| Model | Random AUC | Temporal AUC | Fark |")
        lines.append("|-------|-----------:|-------------:|-----:|")
        for ad, t in temporal.items():
            lines.append(f"| {ad} | {t['random_split_auc']:.4f} | "
                         f"{t['temporal_auc']:.4f} | "
                         f"{t['auc_fark']:+.4f} |")
        lines.append("")

    # ----- Tablo 2 — Brier -----
    lines.append("## Tablo 2 — Kalibrasyon (Brier Score)")
    lines.append("")
    lines.append("Sigmoid kalibrasyonun Brier skoru ne kadar dusurdugu (kucuk = daha iyi).")
    lines.append("")
    lines.append("| Model | Brier (Ham) | Brier (Kalibre) | Iyilesme % |")
    lines.append("|-------|------------:|----------------:|-----------:|")
    if kalibrasyon:
        for ad, k in kalibrasyon.items():
            lines.append(f"| {ad} | {k['brier_ham']:.5f} | "
                         f"{k['brier_kalibre']:.5f} | {k['iyilesme_yuzde']:+.2f}% |")
    lines.append("")
    lines.append("![Reliability Diagram](sonuclar/reliability_grid.png)")
    lines.append("")

    # ----- Tablo 3 — SHAP -----
    lines.append("## Tablo 3 — SHAP Top 5 Feature (her model)")
    lines.append("")
    if shap_top:
        for ad, top5 in shap_top.items():
            siralama = ", ".join(f"`{t['feature']}` ({t['mean_abs_shap']:.3f})"
                                 for t in top5)
            lines.append(f"- **{ad}**: {siralama}")
        lines.append("")
        lines.append("**Figurler:**")
        lines.append("")
        for ad in shap_top:
            lines.append(f"- {ad}: [summary](sonuclar/04_shap/{ad}_summary.png) | "
                         f"[bar](sonuclar/04_shap/{ad}_bar.png)")
        lines.append("")

    # ----- Tablo 4 — Agirliklarin Veriden Turetilmesi (Analiz 7) -----
    lines.append("## Tablo 4 — Yasam Tarzi Agirliklarinin Veriden Turetilmesi")
    lines.append("")
    lines.append("Mevcut tasarim agirliklari (ekran=0.40, uyku=0.35, aktivite=0.25) "
                 "NSCH 2022+2023 verisinde standardize logistic regression ile dogrulandi.")
    lines.append("")
    lines.append("**Iki yontem:**")
    lines.append("- **Yontem A (ham):** Ham predictor'lar (ekran_saat, uyku_saat, aktivite_gun)")
    lines.append("- **Yontem B (risk komponent):** risk_engine komponentleri (uyku U-sekli duzeltilmis)")
    lines.append("")
    lines.append("| Bilesen | Orijinal (eski) | Yontem A | Yontem B (final) |")
    lines.append("|---------|----------------:|---------:|-----------------:|")
    if agirlik:
        orig = agirlik['orijinal_agirliklar']
        yA = agirlik['yontem_a_ham_input']['ortalama_agirlik']
        yB = agirlik['yontem_b_risk_komponent']['ortalama_agirlik']
        for k in ['ekran', 'uyku', 'aktivite']:
            lines.append(f"| {k} | {orig[k]:.3f} | {yA[k]:.3f} | **{yB[k]:.3f}** |")
        lines.append("")
        final = agirlik['final_oneri']
        lines.append(f"**Final:** Yontem B onerilir — {final['yorum']}")
        lines.append("")
        # Yuvarlamayi tutarli yap (toplam=1.00) — uretim kodundaki degerler
        lines.append(f"**Uretim guncellemesi:** risk_engine.py:325 ekran=0.30, uyku=0.26, aktivite=0.44 "
                     f"(ham: ekran={final['agirliklar']['ekran']:.4f}, "
                     f"uyku={final['agirliklar']['uyku']:.4f}, aktivite={final['agirliklar']['aktivite']:.4f})")
        lines.append("")
        lines.append("![Agirlik Karsilastirma](sonuclar/07_agirlik_karsilastirma.png)")
        lines.append("")

    # ----- Tablo 5 — Sensitivity -----
    lines.append("## Tablo 5 — Yasam Tarzi Agirliklarinin Duyarlilik Analizi")
    lines.append("")
    lines.append("Yeni veri-bazli baseline (0.30, 0.26, 0.44) +/-10pp perturbasyonlar.")
    lines.append("")
    if sensitivity:
        lines.append(f"**Agirlik kaynagi:** {sensitivity.get('agirlik_kaynagi', 'N/A')}")
        lines.append(f"**Orneklem:** {sensitivity['orneklem']} cocuk (NSCH 2023)")
    lines.append("")
    lines.append("| Varyant | Agirliklar | Spearman rho | Kategori degisim % | |delta_skor| ort |")
    lines.append("|---------|-----------|-------------:|-------------------:|----------------:|")
    if sensitivity:
        for ad, v in sensitivity['varyantlar'].items():
            w = ", ".join(f"{x:.2f}" for x in v['agirliklar'])
            lines.append(f"| {ad} | ({w}) | {v['spearman_rho']:.4f} | "
                         f"{v['kategori_degisim_yuzde']:.2f}% | "
                         f"{v['ortalama_mutlak_skor_farki']:.3f} |")
    lines.append("")
    lines.append("**Yorum:** Spearman rho > 0.95 ve kategori degisim < %5 ise sistem 'robust' kabul edilir.")
    lines.append("")
    lines.append("![Sensitivity Dagilim](sonuclar/sensitivity_dagilim.png)")
    lines.append("")

    # ----- Tablo 6 — Spearman -----
    lines.append("## Tablo 6 — Birlesik Skorun Dis Dogrulamasi (k2q01)")
    lines.append("")
    if spearman:
        lines.append(f"- **n** = {spearman['n']}")
        lines.append(f"- **Spearman rho** = {spearman['spearman_rho']:.4f} "
                     f"(95% CI: {spearman['rho_95ci_lower']:.4f}–{spearman['rho_95ci_upper']:.4f})")
        lines.append(f"- **p-value** = {spearman['p_value']:.2e}")
        lines.append(f"- **Yorum**: {spearman['yorum']}")
        lines.append("")
        lines.append("**k2q01 kategorisine gore ortalama birlesik skor:**")
        lines.append("")
        lines.append("| k2q01 | Aciklama | n | Mean skor | Std |")
        lines.append("|------:|----------|--:|----------:|----:|")
        aciklama = {1: "Excellent", 2: "Very Good", 3: "Good", 4: "Fair", 5: "Poor"}
        for k, v in sorted(spearman['k2q01_bin_means'].items(), key=lambda x: int(x[0])):
            lines.append(f"| {k} | {aciklama.get(int(k), '?')} | {v['n']} | "
                         f"{v['mean_birlesik_skor']:.2f} | {v['std']:.2f} |")
        lines.append("")
    lines.append("![Spearman Scatter](sonuclar/06_spearman_scatter.png)")
    lines.append("")

    out_p = SONUC_DIR / "RAPOR.md"
    out_p.write_text("\n".join(lines), encoding='utf-8')
    print(f"Rapor: {out_p}")


def main() -> None:
    if "--rapor" in sys.argv:
        rapor_uret()
        return
    calistir()
    rapor_uret()


if __name__ == "__main__":
    main()
