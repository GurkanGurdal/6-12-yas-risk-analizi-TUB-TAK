"""
Analiz 7 — Yasam Tarzi Agirliklarinin Veriden Turetilmesi (2 Yontem)

Mevcut agirliklar (ekran=0.40, uyku=0.35, aktivite=0.25) tasarim kararidir.
Bu analiz iki tamamlayici yontemle veriye-dayali agirliklari turetir.

YONTEM A — Ham predictor regression:
  Predictor'lar: ekran_saat, uyku_saat, aktivite_gun (z-score)
  Sinirlama: Uyku-saglik U-sekilli iliski lineer model tarafindan
            yakalanmaz -> uyku katsayisi olduğundan dusuk cikar.

YONTEM B — Risk komponent regression (U-sekli duzeltilmis):
  Predictor'lar: ekran_risk, uyku_risk, aktivite_risk (z-score)
  risk_engine.risk_komponentleri ile hesaplanan, kilavuza-uzaklik bazli
  MONOTON skorlar. Uyku icin |sleep - guideline| tarzi donusum sayesinde
  U-sekli problemi sifirlanir.

Outcome'lar (her iki yontemde ayni):
  k2q01_kotu, anksiyete, depresyon, dehb, davranis, gelisim_gecikmesi,
  any_psych

Final agirlik: Yontem B (uyku icin metodolojik olarak dogru) onerilir;
Yontem A karsilastirma icin sunulur.
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
from sklearn.linear_model import LogisticRegression
from sklearn.preprocessing import StandardScaler

sys.path.insert(0, str(Path(__file__).resolve().parent))
from _ortak import (
    KLINIK_HEDEF, NSCH_PHYSACTIV_SEVIYE, NSCH_SCREENTIME_SAAT,
    SONUC_DIR, risk_komponentleri, uyku_saat_donustur, veri_yukle,
)

ORIJINAL = {'ekran': 0.40, 'uyku': 0.35, 'aktivite': 0.25}


def hazir_veri() -> pd.DataFrame:
    """2022+2023 birlestirilmis veri + risk komponentleri + outcome'lar."""
    df = veri_yukle(None)

    sutunlar = ['sc_age_years', 'sc_sex', 'screentime', 'physactiv',
                'hoursleep', 'hoursleep05', 'k2q01']
    sutunlar += list(KLINIK_HEDEF.values())
    for c in sutunlar:
        if c in df.columns:
            df[c] = pd.to_numeric(df[c], errors='coerce')

    # KRITIK: NSCH hoursleep/hoursleep05 SAAT degil KATEGORI -> donusum yap
    df['uyku'] = uyku_saat_donustur(df)
    df['ekran_saat'] = df['screentime'].map(NSCH_SCREENTIME_SAAT)
    df['aktivite_gun'] = df['physactiv'].map(NSCH_PHYSACTIV_SEVIYE)

    # Risk komponentleri (her satir icin)
    cek = df[['sc_age_years', 'uyku', 'ekran_saat', 'aktivite_gun']].copy()
    mask = cek.notna().all(axis=1)
    er = np.full(len(df), np.nan)
    ur = np.full(len(df), np.nan)
    ar = np.full(len(df), np.nan)
    for i in cek[mask].index:
        e, u, a = risk_komponentleri(
            int(cek.at[i, 'sc_age_years']),
            float(cek.at[i, 'uyku']),
            float(cek.at[i, 'ekran_saat']),
            int(cek.at[i, 'aktivite_gun']),
        )
        er[i] = e
        ur[i] = u
        ar[i] = a
    df['ekran_risk'] = er
    df['uyku_risk'] = ur
    df['aktivite_risk'] = ar

    df['k2q01_kotu'] = (df['k2q01'].between(3, 5)).astype(float)
    df.loc[~df['k2q01'].between(1, 5), 'k2q01_kotu'] = np.nan

    for ad, col in KLINIK_HEDEF.items():
        df[f'{ad}_outcome'] = df[col].map({1: 1, 2: 0})

    psych = [f'{ad}_outcome' for ad in ['anksiyete', 'depresyon', 'dehb', 'davranis']]
    df['any_psych'] = df[psych].max(axis=1)

    return df


def regresyon(df: pd.DataFrame, predictor_cols: list[str], outcome: str) -> dict | None:
    """Verilen predictor'lar icin standardize logistic regression. Agirlik = |coef|/sum."""
    cols = predictor_cols + ['sc_age_years', 'sc_sex', outcome]
    sub = df[cols].dropna().copy()
    if len(sub) < 1000:
        return None

    X = sub[predictor_cols + ['sc_age_years', 'sc_sex']].values
    y = sub[outcome].astype(int).values
    if len(np.unique(y)) < 2:
        return None

    Xs = StandardScaler().fit_transform(X)
    m = LogisticRegression(max_iter=2000, random_state=42, solver='lbfgs')
    m.fit(Xs, y)

    coefs = m.coef_[0]
    yasam_abs = {
        'ekran': abs(coefs[0]),
        'uyku': abs(coefs[1]),
        'aktivite': abs(coefs[2]),
    }
    toplam = sum(yasam_abs.values())
    norm = {k: v / toplam for k, v in yasam_abs.items()}

    return {
        'n': int(len(sub)),
        'pos_oran': round(float(y.mean()), 4),
        'ham_coef': {
            'ekran': round(float(coefs[0]), 4),
            'uyku': round(float(coefs[1]), 4),
            'aktivite': round(float(coefs[2]), 4),
            'yas_kontrol': round(float(coefs[3]), 4),
            'cinsiyet_kontrol': round(float(coefs[4]), 4),
        },
        'mutlak_coef': {k: round(v, 4) for k, v in yasam_abs.items()},
        'agirlik': {k: round(v, 4) for k, v in norm.items()},
    }


def yontem_calistir(df: pd.DataFrame, predictor_cols: list[str], yontem_ad: str) -> dict:
    """Tum outcome'lar uzerinde yontemi koştur, agirlik ortalamasini al."""
    print(f"\n--- {yontem_ad} ---")
    print(f"  {'Outcome':<35} {'n':>6}  {'pos%':>5}  {'ekran':>6} {'uyku':>6} {'aktiv':>6}")
    print(f"  {'-'*35} {'-'*6}  {'-'*5}  {'-'*6} {'-'*6} {'-'*6}")

    outcomes = [
        ('k2q01_kotu', 'Genel Saglik (k2q01 kotu)'),
        ('anksiyete_outcome', 'Anksiyete'),
        ('depresyon_outcome', 'Depresyon'),
        ('dehb_outcome', 'DEHB'),
        ('davranis_outcome', 'Davranis Bozuklugu'),
        ('gelisim_gecikmesi_outcome', 'Gelisim Gecikmesi'),
        ('any_psych', 'Herhangi Psikolojik Tani'),
    ]

    sonuclar = {}
    for col, ad in outcomes:
        r = regresyon(df, predictor_cols, col)
        if r is None:
            print(f"  {ad:<35} (yetersiz)")
            continue
        sonuclar[col] = {'aciklama': ad, **r}
        a = r['agirlik']
        print(f"  {ad:<35} {r['n']:>6}  {r['pos_oran']*100:>4.1f}%  "
              f"{a['ekran']:.3f}  {a['uyku']:.3f}  {a['aktivite']:.3f}")

    if not sonuclar:
        return None

    ek = float(np.mean([s['agirlik']['ekran'] for s in sonuclar.values()]))
    uy = float(np.mean([s['agirlik']['uyku'] for s in sonuclar.values()]))
    ak = float(np.mean([s['agirlik']['aktivite'] for s in sonuclar.values()]))
    toplam = ek + uy + ak
    ortalama = {'ekran': ek/toplam, 'uyku': uy/toplam, 'aktivite': ak/toplam}

    print(f"  {'ORTALAMA':<35} {'':>6}  {'':>5}  "
          f"{ortalama['ekran']:.3f}  {ortalama['uyku']:.3f}  {ortalama['aktivite']:.3f}")

    return {'outcome_bazli': sonuclar, 'ortalama_agirlik': ortalama}


def main() -> None:
    print("=" * 70)
    print("ANALIZ 7 — YASAM TARZI AGIRLIKLARI (2 YONTEM, V2)")
    print("=" * 70)

    t0 = time.time()
    print("\n[1/4] Veri yukleniyor + risk komponentleri hesaplaniyor...")
    df = hazir_veri()
    print(f"  Toplam: {len(df)} satir")
    print(f"  Risk komponentleri hesaplanan: {df['ekran_risk'].notna().sum()} satir")

    print("\n[2/4] YONTEM A — Ham input regression")
    yA = yontem_calistir(df, ['ekran_saat', 'uyku', 'aktivite_gun'],
                         'YONTEM A — Ham (ekran_saat, uyku_saat, aktivite_gun)')

    print("\n[3/4] YONTEM B — Risk komponent regression (U-sekli duzeltilmis)")
    yB = yontem_calistir(df, ['ekran_risk', 'uyku_risk', 'aktivite_risk'],
                         'YONTEM B — Risk komponent (ekran_risk, uyku_risk, aktivite_risk)')

    print("\n[4/4] KARSILASTIRMA + final agirliklar")
    print()
    print(f"  {'Bilesen':<10}  {'Orijinal':>10}  {'Yontem A':>10}  {'Yontem B':>10}  {'A vs B':>8}")
    print(f"  {'-'*10}  {'-'*10}  {'-'*10}  {'-'*10}  {'-'*8}")
    for k in ['ekran', 'uyku', 'aktivite']:
        a = yA['ortalama_agirlik'][k]
        b = yB['ortalama_agirlik'][k]
        print(f"  {k:<10}  {ORIJINAL[k]:>10.3f}  {a:>10.3f}  {b:>10.3f}  {b-a:>+8.3f}")

    # Yontem B'yi final olarak oneriyoruz (uyku icin metodolojik olarak dogru)
    final_agirlik = yB['ortalama_agirlik']
    fark_orijinal = {k: final_agirlik[k] - ORIJINAL[k] for k in final_agirlik}
    max_fark = max(abs(v) for v in fark_orijinal.values())

    print(f"\n  ONERI: Yontem B (risk komponent regression) — uyku icin dogru methodoloji")
    print(f"  {'Bilesen':<10}  {'Orijinal':>10}  {'Onerilen':>10}  {'Fark':>8}")
    print(f"  {'-'*10}  {'-'*10}  {'-'*10}  {'-'*8}")
    for k in ['ekran', 'uyku', 'aktivite']:
        print(f"  {k:<10}  {ORIJINAL[k]:>10.3f}  {final_agirlik[k]:>10.3f}  {fark_orijinal[k]:>+8.3f}")

    if max_fark < 0.05:
        yorum = f"GUCLU UYUM: max fark {max_fark:.3f} (<0.05). Orijinal agirliklar veriyle desteklenmektedir."
    elif max_fark < 0.10:
        yorum = f"ILIMLI UYUM: max fark {max_fark:.3f}. Yon dogru ama ince ayar yapilabilir."
    else:
        yorum = f"ONEMLI FARK: max fark {max_fark:.3f}. Agirliklar veri-bazli degerlere guncellenebilir."
    print(f"\n  Yorum: {yorum}")

    cikti = {
        'orijinal_agirliklar': ORIJINAL,
        'yontem_a_ham_input': {
            'aciklama': 'Logistic regression on raw inputs (ekran_saat, uyku_saat, aktivite_gun)',
            'sinirlama': 'Lineer model uyku-saglik U-sekli iliskiyi yakalayamaz',
            'ortalama_agirlik': {k: round(v, 4) for k, v in yA['ortalama_agirlik'].items()},
            'outcome_bazli': yA['outcome_bazli'],
        },
        'yontem_b_risk_komponent': {
            'aciklama': 'Logistic regression on risk components (ekran_risk, uyku_risk, aktivite_risk)',
            'avantaj': 'Risk komponentleri MONOTON (kilavuzdan uzaklik) -> U-sekli problemi yok',
            'ortalama_agirlik': {k: round(v, 4) for k, v in yB['ortalama_agirlik'].items()},
            'outcome_bazli': yB['outcome_bazli'],
        },
        'final_oneri': {
            'kaynak': 'Yontem B (risk komponent regression)',
            'agirliklar': {k: round(v, 4) for k, v in final_agirlik.items()},
            'fark_orijinalden': {k: round(v, 4) for k, v in fark_orijinal.items()},
            'max_mutlak_fark': round(max_fark, 4),
            'yorum': yorum,
        },
    }

    out_p = SONUC_DIR / "07_agirlik_turetme.json"
    with open(out_p, 'w', encoding='utf-8') as f:
        json.dump(cikti, f, indent=2, ensure_ascii=False)
    print(f"\nKaydedildi: {out_p}")

    fig, (ax1, ax2) = plt.subplots(1, 2, figsize=(15, 5))

    bilesenler = ['Ekran', 'Uyku', 'Aktivite']
    keys = ['ekran', 'uyku', 'aktivite']
    x = np.arange(len(bilesenler))
    w = 0.27

    o = [ORIJINAL[k] for k in keys]
    a = [yA['ortalama_agirlik'][k] for k in keys]
    b = [yB['ortalama_agirlik'][k] for k in keys]

    ax1.bar(x - w, o, w, label='Orijinal (tasarim)', color='#3498db', edgecolor='black')
    ax1.bar(x, a, w, label='Yontem A (ham)', color='#e67e22', edgecolor='black')
    ax1.bar(x + w, b, w, label='Yontem B (risk komp.)', color='#e74c3c', edgecolor='black')

    for i in range(3):
        ax1.text(i - w, o[i] + 0.005, f'{o[i]:.3f}', ha='center', fontsize=9, fontweight='bold')
        ax1.text(i, a[i] + 0.005, f'{a[i]:.3f}', ha='center', fontsize=9)
        ax1.text(i + w, b[i] + 0.005, f'{b[i]:.3f}', ha='center', fontsize=9, fontweight='bold')

    ax1.set_ylabel('Normalize edilmis agirlik')
    ax1.set_title('Yasam Tarzi Risk Agirliklari — 3 Yaklasim\n(Yontem B U-sekli problemi cozulmus halde)')
    ax1.set_xticks(x)
    ax1.set_xticklabels(bilesenler)
    ax1.legend()
    ax1.grid(alpha=0.3, axis='y')
    ax1.set_ylim(0, max(max(o), max(a), max(b)) * 1.18)

    outcome_adlar = [s['aciklama'] for s in yB['outcome_bazli'].values()]
    ekran_per = [s['agirlik']['ekran'] for s in yB['outcome_bazli'].values()]
    uyku_per = [s['agirlik']['uyku'] for s in yB['outcome_bazli'].values()]
    aktiv_per = [s['agirlik']['aktivite'] for s in yB['outcome_bazli'].values()]
    y_pos = np.arange(len(outcome_adlar))
    ax2.barh(y_pos, ekran_per, label='Ekran', color='#3498db')
    ax2.barh(y_pos, uyku_per, left=ekran_per, label='Uyku', color='#2ecc71')
    ax2.barh(y_pos, aktiv_per, left=[e+u for e, u in zip(ekran_per, uyku_per)],
             label='Aktivite', color='#e67e22')
    ax2.set_yticks(y_pos)
    ax2.set_yticklabels(outcome_adlar, fontsize=9)
    ax2.set_xlabel('Agirlik (toplam=1)')
    ax2.set_title('Yontem B — Outcome Bazinda Agirlik Dagilimi')
    ax2.legend(loc='lower right')
    ax2.set_xlim(0, 1)
    ax2.invert_yaxis()

    plt.tight_layout()
    fig_p = SONUC_DIR / "07_agirlik_karsilastirma.png"
    plt.savefig(fig_p, dpi=200, bbox_inches='tight')
    plt.close()
    print(f"Figur: {fig_p}")
    print(f"\nSure: {time.time() - t0:.1f}s")


if __name__ == "__main__":
    main()
