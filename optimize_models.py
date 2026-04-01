"""
Optuna ile XGBoost Hiperparametre Optimizasyonu

Her model için en iyi AUC'yi veren parametreleri arar,
sonra bu parametrelerle yeniden eğitir.
"""

import pyreadstat
import pandas as pd
import numpy as np
import joblib
import json
import optuna
from sklearn.model_selection import train_test_split, StratifiedKFold, cross_val_score
from sklearn.metrics import roc_auc_score, f1_score, recall_score, precision_score, confusion_matrix
from sklearn.calibration import CalibratedClassifierCV
from xgboost import XGBClassifier

optuna.logging.set_verbosity(optuna.logging.WARNING)

# =============================================================================
# 1. VERİ YÜKLEME
# =============================================================================
print("Veri yükleniyor...")
df_2023, _ = pyreadstat.read_dta(r"veri_seti\nsch_2023e_topical_Stata\nsch_2023e_topical.dta")
df_2022, _ = pyreadstat.read_dta(r"veri_seti\nsch_2022_topical_Stata\nsch_2022e_topical.dta")
df = pd.concat([df_2022, df_2023], ignore_index=True)
print(f"Toplam: {len(df)} satır")

# =============================================================================
# 2. ÖZELLİK HAZIRLAMA
# =============================================================================
ham = ['sc_age_years', 'sc_sex', 'screentime', 'hoursleep', 'hoursleep05',
       'physactiv', 'bedtime', 'bmiclass', 'height', 'weight',
       'outdoorswkday', 'outdoorswkend']

klinik = {
    'anksiyete': 'k2q33a',
    'depresyon': 'k2q32a',
    'dehb': 'k2q31a',
    'davranis': 'k2q34a',
    'gelisim_gecikmesi': 'k2q36a',
}

tum_sutunlar = ham + list(klinik.values())
mevcut = [c for c in tum_sutunlar if c in df.columns]
df_model = df[mevcut].copy()
for col in mevcut:
    df_model[col] = pd.to_numeric(df_model[col], errors='coerce')

df_model['uyku'] = df_model['hoursleep'].fillna(df_model['hoursleep05'])
mask = (df_model['height'].notna()) & (df_model['weight'].notna()) & (df_model['height'] > 0)
df_model.loc[mask, 'bmi'] = df_model.loc[mask, 'weight'] / ((df_model.loc[mask, 'height'] / 100) ** 2)

mask_e = df_model['screentime'].notna()
df_model.loc[mask_e, 'ekran_yas_orani'] = df_model.loc[mask_e, 'screentime'] / (df_model.loc[mask_e, 'sc_age_years'] + 1)
mask_eu = mask_e & df_model['uyku'].notna()
df_model.loc[mask_eu, 'ekran_uyku_orani'] = df_model.loc[mask_eu, 'screentime'] / (df_model.loc[mask_eu, 'uyku'] + 1)
df_model.loc[mask_e, 'ekran_siddeti'] = df_model.loc[mask_e, 'screentime'] ** 2
mask_ea = mask_e & df_model['physactiv'].notna()
df_model.loc[mask_ea, 'hareketsizlik'] = df_model.loc[mask_ea, 'screentime'] / (df_model.loc[mask_ea, 'physactiv'] + 1)
mask_dm = df_model['outdoorswkday'].notna() | df_model['outdoorswkend'].notna()
df_model.loc[mask_dm, 'dis_mekan_ort'] = (df_model['outdoorswkday'].fillna(0) * 5 + df_model['outdoorswkend'].fillna(0) * 2) / 7
mask_ed = mask_e & df_model['dis_mekan_ort'].notna() & (df_model['dis_mekan_ort'] > 0)
df_model.loc[mask_ed, 'ekran_dismekan_orani'] = df_model.loc[mask_ed, 'screentime'] / df_model.loc[mask_ed, 'dis_mekan_ort']

ozellikler = [
    'sc_age_years', 'sc_sex', 'screentime', 'physactiv', 'bedtime',
    'bmiclass', 'height', 'weight', 'outdoorswkday', 'outdoorswkend',
    'uyku', 'bmi', 'ekran_yas_orani', 'ekran_uyku_orani',
    'ekran_siddeti', 'hareketsizlik', 'dis_mekan_ort', 'ekran_dismekan_orani'
]

for ad, col in klinik.items():
    if col in df_model.columns:
        df_model[f'{ad}_hedef'] = df_model[col].map({1: 1, 2: 0})

hedef_sutunlari = [f'{ad}_hedef' for ad in klinik if f'{ad}_hedef' in df_model.columns]
df_model['genel_risk_hedef'] = df_model[hedef_sutunlari].max(axis=1)

# =============================================================================
# 3. HER MODEL İÇİN OPTİMİZASYON
# =============================================================================
tum_modeller = list(klinik.keys()) + ['genel_risk']
hedef_map = {ad: f'{ad}_hedef' for ad in klinik}
hedef_map['genel_risk'] = 'genel_risk_hedef'

sonuclar = {}

for model_ad in tum_modeller:
    hedef_col = hedef_map[model_ad]
    df_sub = df_model[df_model[hedef_col].notna()].copy()
    X = df_sub[ozellikler]
    y = df_sub[hedef_col].astype(int)

    X_train, X_test, y_train, y_test = train_test_split(
        X, y, test_size=0.20, random_state=42, stratify=y
    )

    pozitif_oran = y_train.mean()
    scale_pos = (1 - pozitif_oran) / pozitif_oran

    print(f"\n{'━' * 60}")
    print(f"  {model_ad.upper()} — Optuna optimizasyonu (50 deneme)")
    print(f"{'━' * 60}")

    def objective(trial):
        params = {
            'n_estimators': trial.suggest_int('n_estimators', 200, 800),
            'max_depth': trial.suggest_int('max_depth', 3, 10),
            'learning_rate': trial.suggest_float('learning_rate', 0.01, 0.3, log=True),
            'subsample': trial.suggest_float('subsample', 0.6, 1.0),
            'colsample_bytree': trial.suggest_float('colsample_bytree', 0.5, 1.0),
            'min_child_weight': trial.suggest_int('min_child_weight', 1, 10),
            'gamma': trial.suggest_float('gamma', 0.0, 5.0),
            'reg_alpha': trial.suggest_float('reg_alpha', 0.0, 10.0),
            'reg_lambda': trial.suggest_float('reg_lambda', 0.0, 10.0),
            'scale_pos_weight': scale_pos,
            'eval_metric': 'logloss',
            'random_state': 42,
            'n_jobs': -1,
        }

        xgb = XGBClassifier(**params)
        cv = StratifiedKFold(n_splits=5, shuffle=True, random_state=42)
        scores = cross_val_score(xgb, X_train, y_train, cv=cv, scoring='roc_auc', n_jobs=-1)
        return scores.mean()

    study = optuna.create_study(direction='maximize')
    study.optimize(objective, n_trials=50, show_progress_bar=True)

    best_params = study.best_params
    best_cv_auc = study.best_value
    print(f"  En iyi CV AUC: {best_cv_auc:.4f}")
    print(f"  Parametreler: {best_params}")

    # --- En iyi parametrelerle final model ---
    best_params['scale_pos_weight'] = scale_pos
    best_params['eval_metric'] = 'logloss'
    best_params['random_state'] = 42
    best_params['n_jobs'] = -1

    xgb_best = XGBClassifier(**best_params)
    xgb_best.fit(X_train, y_train)

    # Kalibrasyon
    calibrated = CalibratedClassifierCV(xgb_best, method='sigmoid', cv=5)
    calibrated.fit(X_train, y_train)

    # Test seti değerlendirme
    y_proba = calibrated.predict_proba(X_test)[:, 1]
    auc = roc_auc_score(y_test, y_proba)

    # Optimal threshold (F1 maximize)
    from sklearn.metrics import precision_recall_curve
    prec_arr, rec_arr, thresholds = precision_recall_curve(y_test, y_proba)
    f1_scores = [2*p*r/(p+r) if (p+r) > 0 else 0 for p, r in zip(prec_arr[:-1], rec_arr[:-1])]
    best_idx = np.argmax(f1_scores)
    best_threshold = float(thresholds[best_idx])

    y_pred = (y_proba >= best_threshold).astype(int)
    rec = recall_score(y_test, y_pred)
    prec = precision_score(y_test, y_pred)
    f1 = f1_score(y_test, y_pred)

    print(f"  Test AUC: {auc:.4f}")
    print(f"  Threshold: {best_threshold:.4f}")
    print(f"  Recall: {rec:.4f}, Precision: {prec:.4f}, F1: {f1:.4f}")

    # Kaydet
    joblib.dump(calibrated, f'nsch_{model_ad}_model.pkl')

    sonuclar[model_ad] = {
        'cv_auc': round(best_cv_auc, 4),
        'test_auc': round(auc, 4),
        'optimal_threshold': round(best_threshold, 4),
        'recall': round(rec, 4),
        'precision': round(prec, 4),
        'f1': round(f1, 4),
        'best_params': best_params,
    }

# =============================================================================
# 4. KARŞILAŞTIRMA
# =============================================================================
print("\n" + "=" * 70)
print("SONUÇ KARŞILAŞTIRMA — Eski vs Yeni AUC")
print("=" * 70)

eski_auc = {
    'anksiyete': 0.7803, 'depresyon': 0.8617, 'dehb': 0.7661,
    'davranis': 0.7369, 'gelisim_gecikmesi': 0.6532, 'genel_risk': 0.7323
}

print(f"{'Model':<20} {'Eski AUC':>10} {'Yeni AUC':>10} {'Fark':>10}")
print("─" * 50)
for ad, m in sonuclar.items():
    eski = eski_auc.get(ad, 0)
    yeni = m['test_auc']
    fark = yeni - eski
    ok = "↑" if fark > 0 else ("↓" if fark < 0 else "=")
    print(f"{ad:<20} {eski:>10.4f} {yeni:>10.4f} {ok}{abs(fark):>8.4f}")

# Threshold'ları güncelle
optimal_thresholds = {ad: m['optimal_threshold'] for ad, m in sonuclar.items()}
joblib.dump(optimal_thresholds, 'nsch_optimal_thresholds.pkl')

with open('optimizasyon_sonuc.json', 'w', encoding='utf-8') as f:
    json.dump(sonuclar, f, indent=2, ensure_ascii=False, default=str)

print("\nTüm modeller güncellendi ve kaydedildi!")
