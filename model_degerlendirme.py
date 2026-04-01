"""
Threshold Optimizasyonu + Yeniden Değerlendirme

Her model için:
1. F1-Score'u maximize eden optimal threshold'u bulur
2. Optimal threshold ile Accuracy, Precision, Recall, F1 hesaplar
3. Optimal threshold'ları kaydeder
"""

import pyreadstat
import pandas as pd
import numpy as np
import joblib
import json
from sklearn.model_selection import train_test_split
from sklearn.metrics import (
    accuracy_score, precision_score, recall_score, f1_score,
    roc_auc_score, confusion_matrix, precision_recall_curve,
    classification_report
)

# =============================================================================
# 1. VERİ YÜKLEME (Aynı pipeline)
# =============================================================================
print("Veri yükleniyor...")
df_2023, _ = pyreadstat.read_dta(r"veri_seti\nsch_2023e_topical_Stata\nsch_2023e_topical.dta")
df_2022, _ = pyreadstat.read_dta(r"veri_seti\nsch_2022_topical_Stata\nsch_2022e_topical.dta")
df = pd.concat([df_2022, df_2023], ignore_index=True)

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
# 2. THRESHOLD OPTİMİZASYONU
# =============================================================================
print("\n" + "=" * 70)
print("THRESHOLD OPTİMİZASYONU")
print("=" * 70)

tum_modeller = list(klinik.keys()) + ['genel_risk']
hedef_map = {ad: f'{ad}_hedef' for ad in klinik}
hedef_map['genel_risk'] = 'genel_risk_hedef'

sonuclar = {}
optimal_thresholds = {}

for model_ad in tum_modeller:
    hedef_col = hedef_map[model_ad]
    df_sub = df_model[df_model[hedef_col].notna()].copy()
    X = df_sub[ozellikler]
    y = df_sub[hedef_col].astype(int)

    X_train, X_test, y_train, y_test = train_test_split(
        X, y, test_size=0.20, random_state=42, stratify=y
    )

    model = joblib.load(f'nsch_{model_ad}_model.pkl')
    y_proba = model.predict_proba(X_test)[:, 1]

    # --- Optimal threshold bul (F1 maximize) ---
    precision_arr, recall_arr, thresholds = precision_recall_curve(y_test, y_proba)

    # F1 hesapla her threshold için
    f1_scores = []
    for p, r in zip(precision_arr[:-1], recall_arr[:-1]):
        if p + r > 0:
            f1_scores.append(2 * p * r / (p + r))
        else:
            f1_scores.append(0)

    best_idx = np.argmax(f1_scores)
    best_threshold = float(thresholds[best_idx])
    best_f1 = f1_scores[best_idx]

    optimal_thresholds[model_ad] = best_threshold

    # --- Optimal threshold ile değerlendir ---
    y_pred_opt = (y_proba >= best_threshold).astype(int)

    acc = accuracy_score(y_test, y_pred_opt)
    prec = precision_score(y_test, y_pred_opt, zero_division=0)
    rec = recall_score(y_test, y_pred_opt, zero_division=0)
    f1 = f1_score(y_test, y_pred_opt, zero_division=0)
    auc = roc_auc_score(y_test, y_proba)
    cm = confusion_matrix(y_test, y_pred_opt)
    tn, fp, fn, tp = cm.ravel()
    specificity = tn / (tn + fp) if (tn + fp) > 0 else 0

    # Varsayılan threshold (0.5) ile de hesapla
    y_pred_def = (y_proba >= 0.5).astype(int)
    f1_def = f1_score(y_test, y_pred_def, zero_division=0)
    rec_def = recall_score(y_test, y_pred_def, zero_division=0)

    print(f"\n{'━' * 70}")
    print(f"  MODEL: {model_ad.upper()}")
    print(f"{'━' * 70}")
    print(f"  Varsayılan Threshold (0.50): Recall={rec_def:.4f}, F1={f1_def:.4f}")
    print(f"  Optimal Threshold ({best_threshold:.4f}): Recall={rec:.4f}, F1={f1:.4f}")
    print(f"  ─── İyileşme: F1 {f1_def:.4f} → {f1:.4f}")
    print()
    print(f"  Accuracy:    {acc:.4f}  ({acc:.1%})")
    print(f"  Precision:   {prec:.4f}  ({prec:.1%})")
    print(f"  Recall:      {rec:.4f}  ({rec:.1%})")
    print(f"  F1-Score:    {f1:.4f}  ({f1:.1%})")
    print(f"  ROC-AUC:     {auc:.4f}  ({auc:.1%})")
    print(f"  Specificity: {specificity:.4f}  ({specificity:.1%})")
    print()
    print(f"  Confusion Matrix:")
    print(f"                    Tahmin: Negatif   Tahmin: Pozitif")
    print(f"  Gerçek: Negatif    {tn:>8}          {fp:>8}")
    print(f"  Gerçek: Pozitif    {fn:>8}          {tp:>8}")
    print()
    print(classification_report(y_test, y_pred_opt, target_names=['Negatif', 'Pozitif']))

    sonuclar[model_ad] = {
        'test_satir': len(X_test),
        'pozitif_oran': round(float(y_test.mean()), 4),
        'varsayilan_threshold': 0.5,
        'optimal_threshold': round(best_threshold, 4),
        'varsayilan_f1': round(f1_def, 4),
        'varsayilan_recall': round(rec_def, 4),
        'optimal': {
            'accuracy': round(acc, 4),
            'precision': round(prec, 4),
            'recall': round(rec, 4),
            'f1_score': round(f1, 4),
            'roc_auc': round(auc, 4),
            'specificity': round(specificity, 4),
            'confusion_matrix': {
                'true_negative': int(tn),
                'false_positive': int(fp),
                'false_negative': int(fn),
                'true_positive': int(tp),
            }
        }
    }

# =============================================================================
# 3. ÖZET + KAYDET
# =============================================================================
print("\n" + "=" * 70)
print("ÖZET — Varsayılan vs Optimal Threshold")
print("=" * 70)
print(f"{'Model':<20} {'Threshold':>10} {'Accuracy':>10} {'Precision':>10} {'Recall':>10} {'F1':>10} {'AUC':>10}")
print("─" * 80)
for ad, m in sonuclar.items():
    o = m['optimal']
    print(f"{ad:<20} {m['optimal_threshold']:>10.4f} {o['accuracy']:>10.4f} {o['precision']:>10.4f} {o['recall']:>10.4f} {o['f1_score']:>10.4f} {o['roc_auc']:>10.4f}")

# Threshold'ları kaydet (risk engine kullanabilsin)
joblib.dump(optimal_thresholds, 'nsch_optimal_thresholds.pkl')

sonuclar['optimal_thresholds'] = {k: round(v, 4) for k, v in optimal_thresholds.items()}
with open('model_degerlendirme_optimal.json', 'w', encoding='utf-8') as f:
    json.dump(sonuclar, f, indent=2, ensure_ascii=False)

print(f"\nOptimal threshold'lar: {optimal_thresholds}")
print("Kaydedildi: nsch_optimal_thresholds.pkl, model_degerlendirme_optimal.json")
