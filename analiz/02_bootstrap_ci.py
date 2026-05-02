"""
Analiz 2 — Bootstrap %95 Guven Araliklari

Analiz 1'de egitilen 2022 modelleri uzerinde 2023 test seti icin
1000 bootstrap iterasyonu ile AUC, F1, recall, precision CI'lari uretir.
"""
from __future__ import annotations

import json
import sys
import time
from pathlib import Path

import joblib
import numpy as np
from sklearn.metrics import f1_score, precision_score, recall_score, roc_auc_score

sys.path.insert(0, str(Path(__file__).resolve().parent))
from _ortak import (
    MODEL_2022_DIR, MODEL_LISTESI, OZELLIKLER, SONUC_DIR,
    feature_engineering, hedef_kolonu, hedef_olustur, optimal_threshold,
    veri_yukle,
)

N_BOOTSTRAP = 1000
ALPHA = 0.05  # %95 CI


def bootstrap_metrikler(y_true: np.ndarray, y_proba: np.ndarray, thr: float,
                        n: int = N_BOOTSTRAP, rng: np.random.Generator | None = None) -> dict:
    if rng is None:
        rng = np.random.default_rng(42)
    n_samples = len(y_true)
    aucs, f1s, recs, precs = [], [], [], []
    for _ in range(n):
        idx = rng.integers(0, n_samples, n_samples)
        yt = y_true[idx]
        yp = y_proba[idx]
        # Bootstrap orneginde tek sinif olabilir — auc tanimsiz olur
        if len(np.unique(yt)) < 2:
            continue
        aucs.append(roc_auc_score(yt, yp))
        ypred = (yp >= thr).astype(int)
        f1s.append(f1_score(yt, ypred, zero_division=0))
        recs.append(recall_score(yt, ypred, zero_division=0))
        precs.append(precision_score(yt, ypred, zero_division=0))

    def ci(arr):
        a = np.asarray(arr)
        return {
            'mean': round(float(a.mean()), 4),
            'lower': round(float(np.quantile(a, ALPHA / 2)), 4),
            'upper': round(float(np.quantile(a, 1 - ALPHA / 2)), 4),
            'n_iter': len(a),
        }

    return {
        'auc': ci(aucs),
        'f1': ci(f1s),
        'recall': ci(recs),
        'precision': ci(precs),
    }


def main() -> None:
    print("=" * 70)
    print("ANALIZ 2 — BOOTSTRAP %95 GUVEN ARALIKLARI (1000 iter)")
    print("=" * 70)

    t0 = time.time()
    print("\n[1/2] 2023 verisi + feature engineering...")
    df_23 = veri_yukle('2023')
    fe_23 = hedef_olustur(feature_engineering(df_23))

    print(f"[2/2] {N_BOOTSTRAP} iterasyon x 6 model bootstrap...\n")
    sonuclar: dict = {}
    for model_ad in MODEL_LISTESI:
        hedef = hedef_kolonu(model_ad)
        test_df = fe_23[fe_23[hedef].notna()].copy()
        X_test = test_df[OZELLIKLER]
        y_test = test_df[hedef].astype(int).values

        model = joblib.load(MODEL_2022_DIR / f"nsch_{model_ad}_model.pkl")
        y_proba = model.predict_proba(X_test)[:, 1]
        thr = optimal_threshold(y_test, y_proba)

        ci = bootstrap_metrikler(y_test, y_proba, thr,
                                  rng=np.random.default_rng(42))
        ci['n_test'] = int(len(y_test))
        ci['threshold'] = round(float(thr), 4)

        a = ci['auc']
        f = ci['f1']
        r = ci['recall']
        p = ci['precision']
        print(f"  {model_ad:<20} "
              f"AUC={a['mean']:.4f} ({a['lower']:.4f}-{a['upper']:.4f}) "
              f"F1={f['mean']:.4f} ({f['lower']:.4f}-{f['upper']:.4f})")
        print(f"  {'':<20} "
              f"Recall={r['mean']:.4f} ({r['lower']:.4f}-{r['upper']:.4f}) "
              f"Precision={p['mean']:.4f} ({p['lower']:.4f}-{p['upper']:.4f})")

        sonuclar[model_ad] = ci

    out_p = SONUC_DIR / "02_bootstrap_ci.json"
    with open(out_p, 'w', encoding='utf-8') as f:
        json.dump(sonuclar, f, indent=2, ensure_ascii=False)
    print(f"\nKaydedildi: {out_p}")
    print(f"Sure: {time.time() - t0:.1f}s")


if __name__ == "__main__":
    main()
