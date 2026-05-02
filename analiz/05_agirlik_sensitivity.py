"""
Analiz 5 — Yasam Tarzi Agirliklarinin Duyarlilik Analizi

Baseline (Analiz 7 sonrasi guncellendi): ekran %30, uyku %26, aktivite %44
Perturbasyonlar (her biri ekran ekseninde +/-10pp):
  - ekrana_kayma:    (0.40, 0.16, 0.44)  ekran +10pp, uyku -10pp
  - uykuya_kayma:    (0.20, 0.36, 0.44)  uyku  +10pp, ekran -10pp
  - aktiviteye_kayma:(0.20, 0.26, 0.54)  aktiv +10pp, ekran -10pp

NSCH 2023 verisi uzerinde calisilir.
Spearman korelasyonu ve risk kategorisi degisim yuzdesi raporlanir.

NOT: NSCH hoursleep saat degil KATEGORI - uyku_saat_donustur ile saate cevirilir.
"""
from __future__ import annotations

import json
import sys
import time
from pathlib import Path

import matplotlib
matplotlib.use('Agg')
import matplotlib.pyplot as plt
import numpy as np
import pandas as pd
from scipy.stats import spearmanr

sys.path.insert(0, str(Path(__file__).resolve().parent))
from _ortak import (
    NSCH_PHYSACTIV_SEVIYE, NSCH_SCREENTIME_SAAT, SONUC_DIR,
    uyku_saat_donustur, veri_yukle, yasam_tarzi_risk_param,
)


def kategori(skor: float) -> str:
    if skor >= 50: return 'yuksek'
    if skor >= 25: return 'orta'
    return 'dusuk'


def main() -> None:
    print("=" * 70)
    print("ANALIZ 5 — AGIRLIK DUYARLILIK ANALIZI")
    print("=" * 70)

    t0 = time.time()
    print("\n[1/3] NSCH 2023 verisi yukleniyor...")
    df = veri_yukle('2023')
    df['hoursleep'] = pd.to_numeric(df.get('hoursleep'), errors='coerce')
    df['hoursleep05'] = pd.to_numeric(df.get('hoursleep05'), errors='coerce')
    df['sc_age_years'] = pd.to_numeric(df.get('sc_age_years'), errors='coerce')
    df['screentime_n'] = pd.to_numeric(df.get('screentime'), errors='coerce')
    df['physactiv_n'] = pd.to_numeric(df.get('physactiv'), errors='coerce')
    df['yas'] = df['sc_age_years']

    # NSCH hoursleep KATEGORI -> SAAT donusumu (kritik)
    df['uyku'] = uyku_saat_donustur(df)

    mask = df['uyku'].notna() & df['screentime_n'].between(1, 5) & \
           df['physactiv_n'].between(1, 4) & df['yas'].between(0, 17)
    df = df[mask].copy()
    print(f"  Kullanilabilir orneklem: {len(df)} cocuk")

    # Saatlere cevir
    df['ekran_saat'] = df['screentime_n'].map(NSCH_SCREENTIME_SAAT)
    df['aktivite_kat'] = df['physactiv_n'].map(NSCH_PHYSACTIV_SEVIYE)

    print("[2/3] 4 agirlik varianti hesaplaniyor (orijinal + 3 perturbasyon)...")
    varyantlar = {
        'orijinal':         (0.30, 0.26, 0.44),  # Analiz 7 sonrasi guncel
        'ekrana_kayma':     (0.40, 0.16, 0.44),  # ekran +10pp, uyku -10pp
        'uykuya_kayma':     (0.20, 0.36, 0.44),  # uyku  +10pp, ekran -10pp
        'aktiviteye_kayma': (0.20, 0.26, 0.54),  # aktiv +10pp, ekran -10pp
    }

    skor_df = pd.DataFrame()
    for ad, (we, wu, wa) in varyantlar.items():
        skor_df[ad] = df.apply(
            lambda r: yasam_tarzi_risk_param(
                int(r['yas']), float(r['uyku']), float(r['ekran_saat']),
                int(r['aktivite_kat']), w_ekran=we, w_uyku=wu, w_aktivite=wa
            ), axis=1)

    print("[3/3] Spearman + kategori degisimi...\n")
    sonuclar = {'orneklem': int(len(df)), 'varyantlar': {}}
    orijinal = skor_df['orijinal']
    orijinal_kat = orijinal.apply(kategori)

    for ad in varyantlar:
        if ad == 'orijinal':
            continue
        rho, p = spearmanr(orijinal, skor_df[ad])
        kat = skor_df[ad].apply(kategori)
        degisen = (kat != orijinal_kat).mean() * 100
        skor_fark = (skor_df[ad] - orijinal).abs().mean()

        sonuclar['varyantlar'][ad] = {
            'agirliklar': list(varyantlar[ad]),
            'spearman_rho': round(float(rho), 4),
            'p_value': float(p) if not np.isnan(p) else None,
            'kategori_degisim_yuzde': round(float(degisen), 2),
            'ortalama_mutlak_skor_farki': round(float(skor_fark), 3),
        }
        print(f"  {ad:<20} rho={rho:.4f} kat_degisim={degisen:.2f}% "
              f"|delta_skor|={skor_fark:.2f}")

    sonuclar['orijinal_agirliklar'] = list(varyantlar['orijinal'])
    sonuclar['agirlik_kaynagi'] = (
        "Veri-bazli (Analiz 7): NSCH 2022+2023 (n=66464) standardize logistic "
        "regression risk komponentleri uzerinde, 7 outcome ortalamasi"
    )

    # Plot: 4 dagilim ust uste
    fig, ax = plt.subplots(figsize=(11, 6))
    renkler = {'orijinal': 'black', 'uykuya_kayma': '#FF6B6B',
               'ekrana_kayma': '#4ECDC4', 'aktiviteye_kayma': '#FFD93D'}
    for ad in varyantlar:
        ax.hist(skor_df[ad], bins=40, alpha=0.4, label=ad,
                color=renkler[ad], density=True)
    ax.set_xlabel('Yasam tarzi risk skoru')
    ax.set_ylabel('Yogunluk')
    ax.set_title('Agirlik duyarliligi — 4 varyantin skor dagilimi (NSCH 2023)',
                 fontsize=12, fontweight='bold')
    ax.legend()
    ax.grid(alpha=0.3)
    plt.tight_layout()
    fig_p = SONUC_DIR / "sensitivity_dagilim.png"
    plt.savefig(fig_p, dpi=200, bbox_inches='tight')
    plt.close()

    out_p = SONUC_DIR / "05_sensitivity.json"
    with open(out_p, 'w', encoding='utf-8') as f:
        json.dump(sonuclar, f, indent=2, ensure_ascii=False)

    print(f"\nKaydedildi: {out_p}")
    print(f"Figur: {fig_p}")
    print(f"Sure: {time.time() - t0:.1f}s")


if __name__ == "__main__":
    main()
