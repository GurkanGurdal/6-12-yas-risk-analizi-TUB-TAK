"""
Analiz 4 — SHAP Analizi

6 model icin (HAM XGB modelleri uzerinde):
- Summary plot (feature importance + yon)
- Bar chart (mean |SHAP|)
- Top 5 feature listesi (JSON)

Ham modeller kullanilir cunku CalibratedClassifierCV TreeExplainer ile uyumsuz.
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
import shap

sys.path.insert(0, str(Path(__file__).resolve().parent))
from _ortak import (
    MODEL_2022_DIR, MODEL_LISTESI, OZELLIKLER, SONUC_DIR,
    feature_engineering, hedef_kolonu, hedef_olustur, veri_yukle,
)

SHAP_DIR = SONUC_DIR / "04_shap"
N_SAMPLE = 5000  # SHAP icin orneklem boyu


def main() -> None:
    print("=" * 70)
    print("ANALIZ 4 — SHAP ANALIZI (6 model)")
    print("=" * 70)

    t0 = time.time()
    print("\n[1/2] 2023 verisi + feature engineering...")
    df_23 = veri_yukle('2023')
    fe_23 = hedef_olustur(feature_engineering(df_23))

    top_features: dict = {}
    print(f"[2/2] 6 model icin SHAP (max {N_SAMPLE} satir orneklem)...\n")

    for model_ad in MODEL_LISTESI:
        hedef = hedef_kolonu(model_ad)
        sub = fe_23[fe_23[hedef].notna()].copy()
        X = sub[OZELLIKLER]
        if len(X) > N_SAMPLE:
            X = X.sample(N_SAMPLE, random_state=42)

        ham = joblib.load(MODEL_2022_DIR / f"nsch_{model_ad}_model_HAM.pkl")
        explainer = shap.TreeExplainer(ham)
        shap_values = explainer.shap_values(X)

        # Summary plot (beeswarm)
        plt.figure(figsize=(10, 7))
        shap.summary_plot(shap_values, X, show=False, plot_size=None)
        plt.title(f"SHAP Summary — {model_ad}", fontsize=12, fontweight='bold')
        plt.tight_layout()
        sp = SHAP_DIR / f"{model_ad}_summary.png"
        plt.savefig(sp, dpi=200, bbox_inches='tight')
        plt.close()

        # Bar chart (mean |SHAP|)
        plt.figure(figsize=(10, 6))
        shap.summary_plot(shap_values, X, plot_type='bar', show=False)
        plt.title(f"SHAP Feature Importance — {model_ad}", fontsize=12, fontweight='bold')
        plt.tight_layout()
        bp = SHAP_DIR / f"{model_ad}_bar.png"
        plt.savefig(bp, dpi=200, bbox_inches='tight')
        plt.close()

        # Top 5 feature
        mean_abs = np.abs(shap_values).mean(axis=0)
        order = np.argsort(mean_abs)[::-1][:5]
        top5 = [{'feature': OZELLIKLER[i], 'mean_abs_shap': round(float(mean_abs[i]), 5)}
                for i in order]
        top_features[model_ad] = top5

        print(f"  {model_ad:<20} top5: {', '.join(t['feature'] for t in top5)}")

    out_p = SHAP_DIR / "top_features.json"
    with open(out_p, 'w', encoding='utf-8') as f:
        json.dump(top_features, f, indent=2, ensure_ascii=False)
    print(f"\nTop features kaydedildi: {out_p}")
    print(f"Plotlar: {SHAP_DIR}")
    print(f"Sure: {time.time() - t0:.1f}s")


if __name__ == "__main__":
    main()
