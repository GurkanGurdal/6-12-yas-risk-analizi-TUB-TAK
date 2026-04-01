"""
NSCH Veri Setinden Klinik Modeller + Bileşik Genel Risk Modeli

Eğitilen modeller:
1. Anksiyete modeli (k2q33a)
2. Depresyon modeli (k2q32a)  
3. DEHB modeli (k2q31a)
4. Bileşik Genel Risk modeli (herhangi bir tanı var mı?)

Tüm modeller sadece Flutter'dan alınabilecek özelliklerle eğitilir.
Split: %80 eğitim / %20 test
"""

import pyreadstat
import pandas as pd
import numpy as np
import joblib
import json
from sklearn.model_selection import train_test_split
from sklearn.metrics import classification_report, roc_auc_score
from sklearn.calibration import CalibratedClassifierCV
from xgboost import XGBClassifier

# =============================================================================
# 1. VERİ YÜKLEME
# =============================================================================
print("=" * 60)
print("1. VERİ YÜKLEME")
print("=" * 60)

df_2023, _ = pyreadstat.read_dta(
    r"veri_seti\nsch_2023e_topical_Stata\nsch_2023e_topical.dta"
)
df_2022, _ = pyreadstat.read_dta(
    r"veri_seti\nsch_2022_topical_Stata\nsch_2022e_topical.dta"
)
df = pd.concat([df_2022, df_2023], ignore_index=True)
print(f"Toplam: {len(df)} satır")

# =============================================================================
# 2. ÖZELLİK HAZIRLAMA (Flutter'dan alınabilecek)
# =============================================================================
print("\n" + "=" * 60)
print("2. ÖZELLİK HAZIRLAMA")
print("=" * 60)

ham = ['sc_age_years', 'sc_sex', 'screentime', 'hoursleep', 'hoursleep05',
       'physactiv', 'bedtime', 'bmiclass', 'height', 'weight',
       'outdoorswkday', 'outdoorswkend']

# Klinik hedefler
klinik = {
    'anksiyete': 'k2q33a',
    'depresyon': 'k2q32a',
    'dehb': 'k2q31a',
    'davranis': 'k2q34a',
    'gelisim_gecikmesi': 'k2q36a',
}

# Tüm sütunları al
tum_sutunlar = ham + list(klinik.values())
mevcut = [c for c in tum_sutunlar if c in df.columns]
df_model = df[mevcut].copy()

# Sayısala çevir
for col in mevcut:
    df_model[col] = pd.to_numeric(df_model[col], errors='coerce')

# ===== Özellik Mühendisliği =====
df_model['uyku'] = df_model['hoursleep'].fillna(df_model['hoursleep05'])

mask = (df_model['height'].notna()) & (df_model['weight'].notna()) & (df_model['height'] > 0)
df_model.loc[mask, 'bmi'] = (
    df_model.loc[mask, 'weight'] / ((df_model.loc[mask, 'height'] / 100) ** 2)
)

# Ekran odaklı türetilmiş özellikler
mask_e = df_model['screentime'].notna()
df_model.loc[mask_e, 'ekran_yas_orani'] = (
    df_model.loc[mask_e, 'screentime'] / (df_model.loc[mask_e, 'sc_age_years'] + 1)
)

mask_eu = df_model['screentime'].notna() & df_model['uyku'].notna()
df_model.loc[mask_eu, 'ekran_uyku_orani'] = (
    df_model.loc[mask_eu, 'screentime'] / (df_model.loc[mask_eu, 'uyku'] + 1)
)

df_model.loc[mask_e, 'ekran_siddeti'] = df_model.loc[mask_e, 'screentime'] ** 2

mask_ea = df_model['screentime'].notna() & df_model['physactiv'].notna()
df_model.loc[mask_ea, 'hareketsizlik'] = (
    df_model.loc[mask_ea, 'screentime'] / (df_model.loc[mask_ea, 'physactiv'] + 1)
)

mask_dm = df_model['outdoorswkday'].notna() | df_model['outdoorswkend'].notna()
df_model.loc[mask_dm, 'dis_mekan_ort'] = (
    df_model['outdoorswkday'].fillna(0) * 5 + df_model['outdoorswkend'].fillna(0) * 2
) / 7

mask_ed = mask_e & df_model['dis_mekan_ort'].notna() & (df_model['dis_mekan_ort'] > 0)
df_model.loc[mask_ed, 'ekran_dismekan_orani'] = (
    df_model.loc[mask_ed, 'screentime'] / df_model.loc[mask_ed, 'dis_mekan_ort']
)

# Final özellik listesi
ozellikler = [
    'sc_age_years', 'sc_sex', 'screentime', 'physactiv', 'bedtime',
    'bmiclass', 'height', 'weight', 'outdoorswkday', 'outdoorswkend',
    'uyku', 'bmi', 'ekran_yas_orani', 'ekran_uyku_orani',
    'ekran_siddeti', 'hareketsizlik', 'dis_mekan_ort', 'ekran_dismekan_orani'
]

print(f"Özellik sayısı: {len(ozellikler)}")

# =============================================================================
# 3. KLİNİK HEDEF DEĞİŞKENLERİ HAZIRLA
# =============================================================================
print("\n" + "=" * 60)
print("3. KLİNİK HEDEF DEĞİŞKENLER")
print("=" * 60)

# NSCH'de: 1 = Evet (tanı var), 2 = Hayır → 1/0'a çevir
for ad, col in klinik.items():
    if col in df_model.columns:
        # 1 → 1 (tanı var), 2 → 0 (tanı yok)
        df_model[f'{ad}_hedef'] = df_model[col].map({1: 1, 2: 0})
        pozitif = df_model[f'{ad}_hedef'].sum()
        toplam = df_model[f'{ad}_hedef'].notna().sum()
        print(f"  {ad:20s}: {pozitif:>6} pozitif / {toplam:>6} toplam ({pozitif/toplam*100:.1f}%)" if toplam > 0 else f"  {ad}: veri yok")

# Bileşik hedef: herhangi birinde tanı var mı?
hedef_sutunlari = [f'{ad}_hedef' for ad in klinik if f'{ad}_hedef' in df_model.columns]
df_model['genel_risk_hedef'] = df_model[hedef_sutunlari].max(axis=1)
pozitif = df_model['genel_risk_hedef'].sum()
toplam = df_model['genel_risk_hedef'].notna().sum()
print(f"\n  GENEL RİSK (bileşik)  : {int(pozitif):>6} pozitif / {toplam:>6} toplam ({pozitif/toplam*100:.1f}%)")

# =============================================================================
# 4. MODEL EĞİTİMİ
# =============================================================================
print("\n" + "=" * 60)
print("4. MODEL EĞİTİMİ")
print("=" * 60)

tum_modeller = list(klinik.keys()) + ['genel_risk']
hedef_map = {ad: f'{ad}_hedef' for ad in klinik}
hedef_map['genel_risk'] = 'genel_risk_hedef'

sonuclar = {}

for model_ad in tum_modeller:
    hedef_col = hedef_map[model_ad]
    
    print(f"\n{'─' * 50}")
    print(f"  MODEL: {model_ad.upper()}")
    print(f"{'─' * 50}")
    
    # Hedefi olan satırları al
    df_sub = df_model[df_model[hedef_col].notna()].copy()
    
    X = df_sub[ozellikler]
    y = df_sub[hedef_col].astype(int)
    
    # %80 eğitim / %20 test
    X_train, X_test, y_train, y_test = train_test_split(
        X, y, test_size=0.20, random_state=42, stratify=y
    )
    
    pozitif_oran = y_train.mean()
    print(f"  Eğitim: {len(X_train)}, Test: {len(X_test)}")
    print(f"  Pozitif oran: {pozitif_oran:.1%}")
    
    # XGBoost
    scale_pos = (1 - pozitif_oran) / pozitif_oran if pozitif_oran > 0 else 1
    
    xgb = XGBClassifier(
        n_estimators=300,
        max_depth=5,
        learning_rate=0.1,
        subsample=0.8,
        colsample_bytree=0.8,
        scale_pos_weight=scale_pos,
        eval_metric='logloss',
        random_state=42,
        n_jobs=-1,
    )
    xgb.fit(X_train, y_train)
    
    # Kalibrasyon
    calibrated = CalibratedClassifierCV(xgb, method='sigmoid', cv=5)
    calibrated.fit(X_train, y_train)
    
    # Değerlendirme
    y_pred = calibrated.predict(X_test)
    y_proba = calibrated.predict_proba(X_test)[:, 1]
    
    auc = roc_auc_score(y_test, y_proba)
    print(f"\n  ROC-AUC: {auc:.4f}")
    print(classification_report(y_test, y_pred, target_names=['Negatif', 'Pozitif']))
    
    # Feature importance
    importances = xgb.feature_importances_
    fi = sorted(zip(ozellikler, importances), key=lambda x: x[1], reverse=True)
    print("  Top 5 Feature Importance:")
    for name, imp in fi[:5]:
        print(f"    {name:25s} {imp:.4f}")
    
    # Kaydet
    joblib.dump(calibrated, f'nsch_{model_ad}_model.pkl')
    
    sonuclar[model_ad] = {
        'auc': round(auc, 4),
        'egitim_satir': len(X_train),
        'test_satir': len(X_test),
        'pozitif_oran': round(float(pozitif_oran), 4),
        'feature_importance': {n: round(float(i), 4) for n, i in fi},
    }

# =============================================================================
# 5. KAYDET
# =============================================================================
print("\n" + "=" * 60)
print("5. KAYDET")
print("=" * 60)

joblib.dump(ozellikler, 'nsch_ozellikler.pkl')

sonuclar['ozellikler'] = ozellikler
sonuclar['klinik_hedefler'] = {ad: col for ad, col in klinik.items()}

with open('nsch_model_ozet.json', 'w', encoding='utf-8') as f:
    json.dump(sonuclar, f, indent=2, ensure_ascii=False)

print("Kaydedilen model dosyaları:")
for ad in tum_modeller:
    print(f"  nsch_{ad}_model.pkl")
print("  nsch_ozellikler.pkl")
print("  nsch_model_ozet.json")
print("\nTüm modellerin eğitimi tamamlandı!")
