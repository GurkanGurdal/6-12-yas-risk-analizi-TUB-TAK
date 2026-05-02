"""
Analiz 3 — Kalibrasyon Analizi

Her model icin:
- Brier score (kalibrasyondan once / sonra)
- Reliability diagram (calibration_curve, n_bins=10)
- 2x3 grid figure: 6 model
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
from sklearn.calibration import calibration_curve
from sklearn.metrics import brier_score_loss

sys.path.insert(0, str(Path(__file__).resolve().parent))
from _ortak import (
    MODEL_2022_DIR, MODEL_LISTESI, OZELLIKLER, SONUC_DIR,
    feature_engineering, hedef_kolonu, hedef_olustur, veri_yukle,
)


def main() -> None:
    print("=" * 70)
    print("ANALIZ 3 — KALIBRASYON (Brier + Reliability Diagram)")
    print("=" * 70)

    t0 = time.time()
    print("\n[1/3] 2023 verisi yukleniyor...")
    df_23 = veri_yukle('2023')
    fe_23 = hedef_olustur(feature_engineering(df_23))

    print("[2/3] Her model icin ham vs kalibre Brier hesabi + reliability...\n")
    fig, axes = plt.subplots(2, 3, figsize=(15, 10))
    axes = axes.flatten()

    sonuclar: dict = {}
    for i, model_ad in enumerate(MODEL_LISTESI):
        hedef = hedef_kolonu(model_ad)
        test_df = fe_23[fe_23[hedef].notna()].copy()
        X_test = test_df[OZELLIKLER]
        y_test = test_df[hedef].astype(int).values

        ham = joblib.load(MODEL_2022_DIR / f"nsch_{model_ad}_model_HAM.pkl")
        kalibre = joblib.load(MODEL_2022_DIR / f"nsch_{model_ad}_model.pkl")

        y_proba_ham = ham.predict_proba(X_test)[:, 1]
        y_proba_kal = kalibre.predict_proba(X_test)[:, 1]

        brier_ham = brier_score_loss(y_test, y_proba_ham)
        brier_kal = brier_score_loss(y_test, y_proba_kal)
        iyilesme = (brier_ham - brier_kal) / brier_ham * 100

        # Reliability curve
        prob_true_ham, prob_pred_ham = calibration_curve(y_test, y_proba_ham,
                                                          n_bins=10, strategy='quantile')
        prob_true_kal, prob_pred_kal = calibration_curve(y_test, y_proba_kal,
                                                          n_bins=10, strategy='quantile')

        ax = axes[i]
        ax.plot([0, 1], [0, 1], 'k--', alpha=0.5, label='Mukemmel')
        ax.plot(prob_pred_ham, prob_true_ham, 'o-', color='#FF6B6B',
                label=f'Ham (Brier={brier_ham:.4f})')
        ax.plot(prob_pred_kal, prob_true_kal, 's-', color='#4ECDC4',
                label=f'Kalibre (Brier={brier_kal:.4f})')
        ax.set_xlabel('Tahmin edilen olasilik')
        ax.set_ylabel('Gercek pozitif orani')
        ax.set_title(f'{model_ad}', fontsize=11, fontweight='bold')
        ax.legend(loc='upper left', fontsize=8)
        ax.grid(alpha=0.3)
        ax.set_xlim(0, 1)
        ax.set_ylim(0, 1)

        sonuclar[model_ad] = {
            'brier_ham': round(float(brier_ham), 5),
            'brier_kalibre': round(float(brier_kal), 5),
            'iyilesme_yuzde': round(float(iyilesme), 2),
            'n_test': int(len(y_test)),
        }
        ok = "-" if brier_kal < brier_ham else "+"
        print(f"  {model_ad:<20} Brier ham={brier_ham:.5f} -> kalibre={brier_kal:.5f} "
              f"({ok}{abs(iyilesme):.2f}%)")

    plt.suptitle('Reliability Diagram — Kalibrasyon Oncesi vs Sonrasi (2023 test, 2022 egitim)',
                 fontsize=13, fontweight='bold', y=1.00)
    plt.tight_layout()
    fig_p = SONUC_DIR / "reliability_grid.png"
    plt.savefig(fig_p, dpi=300, bbox_inches='tight')
    plt.close()
    print(f"\nFigur kaydedildi: {fig_p}")

    out_p = SONUC_DIR / "03_kalibrasyon.json"
    with open(out_p, 'w', encoding='utf-8') as f:
        json.dump(sonuclar, f, indent=2, ensure_ascii=False)
    print(f"JSON kaydedildi: {out_p}")
    print(f"Sure: {time.time() - t0:.1f}s")


if __name__ == "__main__":
    main()
