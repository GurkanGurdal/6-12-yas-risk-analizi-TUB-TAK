"""
Analiz 6 — Birlesik Risk Skorunun Dis Dogrulamasi

NSCH 2023 verisinde her cocuk icin birlesik risk skoru hesaplanir,
k2q01 (General Health, 1=Excellent -> 5=Poor) ile Spearman korelasyonu olcur.

Beklenti: Pozitif rho (yuksek skor = kotu saglik).
Model: temporal validasyon icin egitilen 2022-only modeller (analiz/sonuclar/modeller_2022_only/).
"""
from __future__ import annotations

import json
import sys
import time
from pathlib import Path

import joblib
import matplotlib
matplotlib.use('Agg')
import matplotlib.pyplot as plt
import numpy as np
import pandas as pd
from scipy.stats import spearmanr

sys.path.insert(0, str(Path(__file__).resolve().parent))
from _ortak import (
    KOK, MODEL_2022_DIR, MODEL_LISTESI, NSCH_PHYSACTIV_SEVIYE,
    NSCH_SCREENTIME_SAAT, OZELLIKLER, SONUC_DIR,
    feature_engineering, uyku_saat_donustur, veri_yukle,
    yasam_tarzi_risk_param,
)

# Ekleyelim — risk_engine.py'deki growth_norms'i KOK'tan import edebiliriz
sys.path.insert(0, str(KOK))
from growth_norms import fiziksel_gelisim_riski


def ideal_satir(yas: int, sc_sex: int, height: float, weight: float, bmiclass: float) -> dict:
    """Aynı yas/cinsiyet/boy/kilo, kilavuza uygun yasam tarzi (risk_engine._ideal_girdi_olustur).

    NSCH KATEGORILERI kullanilir (ML modelleri kategorik degerlerle egitildi):
      - screentime: 3 -> "2 saat" (kategori)
      - uyku: 4 -> "8 saat" (school-age icin ideal kategori)
      - physactiv: 3 -> "4-6 gun/hafta"
    """
    bmi = weight / ((height / 100) ** 2) if height and height > 0 else np.nan
    ideal_ekran = 3      # NSCH kategori 3 = 2 saat
    ideal_uyku = 4       # NSCH hoursleep kategori 4 = 8 saat (school-age ideal)
    ideal_aktivite = 3   # NSCH physactiv kategori 3 = 4-6 gun/hafta
    ideal_bedtime = 2
    ideal_outdoor = 3
    return {
        'sc_age_years': yas,
        'sc_sex': sc_sex,
        'screentime': ideal_ekran,
        'physactiv': ideal_aktivite,
        'bedtime': ideal_bedtime,
        'bmiclass': bmiclass,
        'height': height,
        'weight': weight,
        'outdoorswkday': ideal_outdoor,
        'outdoorswkend': ideal_outdoor,
        'uyku': ideal_uyku,
        'bmi': bmi,
        'ekran_yas_orani': ideal_ekran / (yas + 1),
        'ekran_uyku_orani': ideal_ekran / (ideal_uyku + 1),
        'ekran_siddeti': ideal_ekran ** 2,
        'hareketsizlik': ideal_ekran / (ideal_aktivite + 1),
        'dis_mekan_ort': ideal_outdoor,
        'ekran_dismekan_orani': ideal_ekran / ideal_outdoor,
    }


def main() -> None:
    print("=" * 70)
    print("ANALIZ 6 — BIRLESIK SKORUN DIS DOGRULAMASI (k2q01)")
    print("=" * 70)

    t0 = time.time()
    print("\n[1/5] NSCH 2023 verisi + k2q01 filtre...")
    df = veri_yukle('2023')

    df['k2q01_n'] = pd.to_numeric(df.get('k2q01'), errors='coerce')
    n_once = len(df)
    df = df[df['k2q01_n'].between(1, 5)].copy()
    print(f"  Toplam: {n_once} -> k2q01 gecerli (1-5): {len(df)} satir")

    print("[2/5] Feature engineering (gercek girdiler)...")
    # Ham df'te hoursleep/hoursleep05'i numerik yap (uyku_saat_donustur icin)
    df['hoursleep'] = pd.to_numeric(df.get('hoursleep'), errors='coerce')
    df['hoursleep05'] = pd.to_numeric(df.get('hoursleep05'), errors='coerce')
    df['sc_age_years_n'] = pd.to_numeric(df.get('sc_age_years'), errors='coerce')
    # Yas-duyarli kategori -> saat donusumu
    df_helper = pd.DataFrame({
        'sc_age_years': df['sc_age_years_n'].values,
        'hoursleep': df['hoursleep'].values,
        'hoursleep05': df['hoursleep05'].values,
    })
    uyku_saat_seri = uyku_saat_donustur(df_helper).reset_index(drop=True)

    df_real = feature_engineering(df).reset_index(drop=True)
    df_real['k2q01'] = df['k2q01_n'].reset_index(drop=True).values
    df_real['uyku_saat'] = uyku_saat_seri.values

    # Cekirdek girdiler dolu olmali (yas, cinsiyet, ekran, uyku, aktivite, boy, kilo)
    cekirdek = ['sc_age_years', 'sc_sex', 'screentime', 'uyku',
                'physactiv', 'height', 'weight']
    mask = df_real[cekirdek].notna().all(axis=1)
    df_real = df_real[mask].copy()
    print(f"  Cekirdek girdiler dolu: {len(df_real)} satir")

    print("[3/5] Ideal (kilavuz-uyumlu) baseline satirlari uretiliyor...")
    ideal_rows = []
    for _, r in df_real.iterrows():
        yas = int(r['sc_age_years']) if pd.notna(r['sc_age_years']) else 8
        sex = int(r['sc_sex']) if pd.notna(r['sc_sex']) else 1
        h = float(r['height']) if pd.notna(r['height']) else 130.0
        w = float(r['weight']) if pd.notna(r['weight']) else 30.0
        bcl = float(r['bmiclass']) if pd.notna(r['bmiclass']) else 2.0
        ideal_rows.append(ideal_satir(yas, sex, h, w, bcl))
    df_ideal = pd.DataFrame(ideal_rows)[OZELLIKLER]

    print("[4/5] ML modelleri (2022-only) uzerinde batch tahmin...")
    ek_risk_df = pd.DataFrame(index=df_real.index)
    for ad in MODEL_LISTESI:
        model = joblib.load(MODEL_2022_DIR / f"nsch_{ad}_model.pkl")
        p_real = model.predict_proba(df_real[OZELLIKLER])[:, 1]
        p_ideal = model.predict_proba(df_ideal)[:, 1]
        ek = (p_real - p_ideal) * 100
        ek_risk_df[ad] = np.clip(ek, 0, 100)

    print("[5/5] Yasam tarzi + fiziksel risk + birlesik skor...")
    # NSCH kategorik degerleri SAATE/SEVIYEYE cevir
    df_real['ekran_saat'] = df_real['screentime'].map(NSCH_SCREENTIME_SAAT)
    df_real['aktivite_kat'] = df_real['physactiv'].map(NSCH_PHYSACTIV_SEVIYE)
    # uyku_saat zaten yukarida (feature_engineering oncesi) hesaplandi

    yasam_riski = []
    fiziksel_riski = []
    for _, r in df_real.iterrows():
        yas = int(r['sc_age_years'])
        sex = int(r['sc_sex'])
        uyku_saat = float(r['uyku_saat']) if pd.notna(r['uyku_saat']) else 8.0
        ek_saat = float(r['ekran_saat']) if pd.notna(r['ekran_saat']) else 2.0
        akt = int(r['aktivite_kat']) if pd.notna(r['aktivite_kat']) else 1
        h = float(r['height'])
        w = float(r['weight'])

        yasam_riski.append(yasam_tarzi_risk_param(yas, uyku_saat, ek_saat, akt))

        try:
            f = fiziksel_gelisim_riski(yas, sex - 1, h, w)
            fiziksel_riski.append(f['risk_puani'])
        except Exception:
            fiziksel_riski.append(np.nan)

    df_real['yasam_tarzi_risk'] = yasam_riski
    df_real['fiziksel_risk'] = fiziksel_riski

    # birlesik_risk_hesapla mantigi (vektorize):
    # psikolojik_ort = mean(anksiyete, depresyon, dehb, davranis)
    # fiziksel_birlesik = fiziksel_risk * 0.6 + ek('gelisim_gecikmesi') * 0.4
    # final = max(0, psikolojik_ort + yasam_tarzi_risk + fiziksel_birlesik)
    psi_ort = ek_risk_df[['anksiyete', 'depresyon', 'dehb', 'davranis']].mean(axis=1)
    fiz_bir = df_real['fiziksel_risk'] * 0.6 + ek_risk_df['gelisim_gecikmesi'] * 0.4
    birlesik = (psi_ort + df_real['yasam_tarzi_risk'] + fiz_bir).clip(lower=0)

    df_real['birlesik_skor'] = birlesik

    valid = df_real[df_real['birlesik_skor'].notna() & df_real['k2q01'].notna()].copy()
    print(f"\n  Korelasyon ornek boyu: {len(valid)}")

    rho, p = spearmanr(valid['birlesik_skor'], valid['k2q01'])
    print(f"  Spearman rho = {rho:.4f} (p = {p:.4e})")

    # k2q01 her degeri icin ortalama birlesik skor
    bin_means = valid.groupby('k2q01')['birlesik_skor'].agg(['mean', 'std', 'count'])
    print("\n  k2q01 (1=Excellent, 5=Poor) -> ortalama birlesik skor:")
    for k, row in bin_means.iterrows():
        print(f"    k2q01={int(k)}: mean={row['mean']:.2f} std={row['std']:.2f} n={int(row['count'])}")

    # Bootstrap CI for rho
    rng = np.random.default_rng(42)
    boot_rhos = []
    for _ in range(1000):
        idx = rng.integers(0, len(valid), len(valid))
        r, _ = spearmanr(valid['birlesik_skor'].values[idx], valid['k2q01'].values[idx])
        boot_rhos.append(r)
    rho_lo = float(np.quantile(boot_rhos, 0.025))
    rho_hi = float(np.quantile(boot_rhos, 0.975))

    sonuclar = {
        'n': int(len(valid)),
        'spearman_rho': round(float(rho), 4),
        'rho_95ci_lower': round(rho_lo, 4),
        'rho_95ci_upper': round(rho_hi, 4),
        'p_value': float(p),
        'k2q01_bin_means': {int(k): {'mean_birlesik_skor': round(float(v['mean']), 2),
                                     'std': round(float(v['std']), 2),
                                     'n': int(v['count'])}
                            for k, v in bin_means.iterrows()},
        'yorum': ('Anlamli pozitif korelasyon (yuksek risk = kotu saglik)'
                  if rho > 0.1 and p < 0.05
                  else 'Zayif/anlamsiz iliski — birlesik skor makaleden cikartilmali'),
    }

    out_p = SONUC_DIR / "06_spearman.json"
    with open(out_p, 'w', encoding='utf-8') as f:
        json.dump(sonuclar, f, indent=2, ensure_ascii=False)
    print(f"\nKaydedildi: {out_p}")

    # Scatter + bin means plot
    fig, (ax1, ax2) = plt.subplots(1, 2, figsize=(13, 5))

    jitter = np.random.default_rng(1).uniform(-0.15, 0.15, len(valid))
    ax1.scatter(valid['k2q01'].values + jitter, valid['birlesik_skor'].values,
                alpha=0.05, s=4, color='#3498db')
    ax1.set_xlabel('k2q01 (Genel Saglik, 1=Excellent .. 5=Poor)')
    ax1.set_ylabel('Birlesik risk skoru')
    ax1.set_title(f'Birlesik skor vs k2q01 (Spearman rho = {rho:.3f}, n={len(valid)})')
    ax1.grid(alpha=0.3)

    ax2.errorbar(bin_means.index.astype(int), bin_means['mean'],
                 yerr=bin_means['std'] / np.sqrt(bin_means['count']),
                 marker='o', capsize=5, color='#e74c3c', linewidth=2)
    ax2.set_xlabel('k2q01')
    ax2.set_ylabel('Ortalama birlesik skor (+/- SEM)')
    ax2.set_title('k2q01 kategorisine gore ortalama birlesik skor')
    ax2.grid(alpha=0.3)

    plt.tight_layout()
    fig_p = SONUC_DIR / "06_spearman_scatter.png"
    plt.savefig(fig_p, dpi=200, bbox_inches='tight')
    plt.close()
    print(f"Figur: {fig_p}")
    print(f"Sure: {time.time() - t0:.1f}s")


if __name__ == "__main__":
    main()
