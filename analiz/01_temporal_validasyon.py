"""
Analiz 1 — Temporal Validasyon

2022 verisiyle egitir, 2023 verisiyle test eder.
6 model icin AUC, F1, recall, precision hesaplar.
Modelleri sonuclar/modeller_2022_only/ icine kaydeder (sonraki analizler kullanir).
"""
from __future__ import annotations

import json
import sys
import time
from pathlib import Path

import joblib
import numpy as np
import pandas as pd
from sklearn.calibration import CalibratedClassifierCV
from sklearn.metrics import (
    f1_score, precision_score, recall_score, roc_auc_score
)
from xgboost import XGBClassifier

sys.path.insert(0, str(Path(__file__).resolve().parent))
from _ortak import (
    KOK, MODEL_2022_DIR, MODEL_LISTESI, OZELLIKLER, SONUC_DIR,
    best_params_yukle, feature_engineering, hedef_kolonu,
    hedef_olustur, optimal_threshold, veri_yukle,
)


def main() -> None:
    print("=" * 70)
    print("ANALIZ 1 — TEMPORAL VALIDASYON (2022 -> 2023)")
    print("=" * 70)

    t0 = time.time()
    print("\n[1/4] Veri yukleniyor (2022 + 2023)...")
    df_22 = veri_yukle('2022')
    df_23 = veri_yukle('2023')
    print(f"  2022: {len(df_22)} satir | 2023: {len(df_23)} satir")

    print("[2/4] Feature engineering...")
    fe_22 = hedef_olustur(feature_engineering(df_22))
    fe_23 = hedef_olustur(feature_engineering(df_23))

    print("[3/4] Hiperparametreler yukleniyor (optimizasyon_sonuc.json)...")
    best_params_map = best_params_yukle()

    print("[4/4] 6 model egitiliyor + 2023 uzerinde degerlendiriliyor...\n")
    sonuclar: dict = {}
    eski_auc_random = {
        'anksiyete': 0.7857, 'depresyon': 0.8680, 'dehb': 0.7735,
        'davranis': 0.7550, 'gelisim_gecikmesi': 0.6694, 'genel_risk': 0.7359,
    }

    for model_ad in MODEL_LISTESI:
        hedef = hedef_kolonu(model_ad)
        train_df = fe_22[fe_22[hedef].notna()].copy()
        test_df = fe_23[fe_23[hedef].notna()].copy()

        X_train = train_df[OZELLIKLER]
        y_train = train_df[hedef].astype(int)
        X_test = test_df[OZELLIKLER]
        y_test = test_df[hedef].astype(int)

        n_train, n_test = len(X_train), len(X_test)
        pos_train = y_train.mean()
        pos_test = y_test.mean()

        # best_params'i temizle: scale_pos_weight 2022 train'e gore yeniden hesaplanir
        params = dict(best_params_map[model_ad])
        params['scale_pos_weight'] = (1 - pos_train) / pos_train if pos_train > 0 else 1.0
        params['eval_metric'] = 'logloss'
        params['random_state'] = 42
        params['n_jobs'] = -1

        ham = XGBClassifier(**params)
        ham.fit(X_train, y_train)

        # Kalibrasyon (sigmoid, 5-fold)
        kalibre = CalibratedClassifierCV(ham, method='sigmoid', cv=5)
        kalibre.fit(X_train, y_train)

        # 2023 uzerinde degerlendirme
        y_proba = kalibre.predict_proba(X_test)[:, 1]
        auc = roc_auc_score(y_test, y_proba)
        thr = optimal_threshold(y_test.values, y_proba)
        y_pred = (y_proba >= thr).astype(int)
        f1 = f1_score(y_test, y_pred, zero_division=0)
        rec = recall_score(y_test, y_pred, zero_division=0)
        prec = precision_score(y_test, y_pred, zero_division=0)

        eski = eski_auc_random.get(model_ad, np.nan)
        fark = auc - eski
        ok = "+" if fark > 0 else ("-" if fark < 0 else "=")

        print(f"  {model_ad:<20} AUC={auc:.4f} ({ok}{abs(fark):+.4f} vs random) "
              f"F1={f1:.4f} Recall={rec:.4f} Precision={prec:.4f}")
        print(f"  {'':<20} thr={thr:.4f} | n_train={n_train} (pos={pos_train:.3f}) "
              f"n_test={n_test} (pos={pos_test:.3f})")

        # Modelleri kaydet
        joblib.dump(kalibre, MODEL_2022_DIR / f"nsch_{model_ad}_model.pkl")
        joblib.dump(ham, MODEL_2022_DIR / f"nsch_{model_ad}_model_HAM.pkl")

        sonuclar[model_ad] = {
            'n_train_2022': int(n_train),
            'n_test_2023': int(n_test),
            'pozitif_oran_train': round(float(pos_train), 4),
            'pozitif_oran_test': round(float(pos_test), 4),
            'temporal_auc': round(float(auc), 4),
            'random_split_auc': round(float(eski), 4),
            'auc_fark': round(float(fark), 4),
            'optimal_threshold': round(float(thr), 4),
            'f1': round(float(f1), 4),
            'recall': round(float(rec), 4),
            'precision': round(float(prec), 4),
        }

    out_p = SONUC_DIR / "01_temporal_metrikler.json"
    with open(out_p, 'w', encoding='utf-8') as f:
        json.dump(sonuclar, f, indent=2, ensure_ascii=False)

    print(f"\nKaydedildi: {out_p}")
    print(f"Modeller: {MODEL_2022_DIR}")
    print(f"Sure: {time.time() - t0:.1f}s")


if __name__ == "__main__":
    main()
