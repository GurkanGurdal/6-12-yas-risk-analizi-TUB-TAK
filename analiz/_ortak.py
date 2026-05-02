"""
Paylasilan yardimcilar — analiz scriptlerinin tumu buradan import eder.

veri_yukle, feature_engineering, hedef_olustur:
optimize_models.py ve model_degerlendirme.py'deki birebir ayni pipeline.
"""
from __future__ import annotations

import json
import os
import sys
from pathlib import Path

import numpy as np
import pandas as pd

KOK = Path(__file__).resolve().parent.parent
SONUC_DIR = Path(__file__).resolve().parent / "sonuclar"
MODEL_2022_DIR = SONUC_DIR / "modeller_2022_only"

OZELLIKLER = [
    'sc_age_years', 'sc_sex', 'screentime', 'physactiv', 'bedtime',
    'bmiclass', 'height', 'weight', 'outdoorswkday', 'outdoorswkend',
    'uyku', 'bmi', 'ekran_yas_orani', 'ekran_uyku_orani',
    'ekran_siddeti', 'hareketsizlik', 'dis_mekan_ort', 'ekran_dismekan_orani'
]

KLINIK_HEDEF = {
    'anksiyete': 'k2q33a',
    'depresyon': 'k2q32a',
    'dehb': 'k2q31a',
    'davranis': 'k2q34a',
    'gelisim_gecikmesi': 'k2q36a',
}

MODEL_LISTESI = list(KLINIK_HEDEF.keys()) + ['genel_risk']

HAM_SUTUNLAR = ['sc_age_years', 'sc_sex', 'screentime', 'hoursleep', 'hoursleep05',
                'physactiv', 'bedtime', 'bmiclass', 'height', 'weight',
                'outdoorswkday', 'outdoorswkend']


def veri_yukle(yil: str | None = None) -> pd.DataFrame:
    """yil = '2022', '2023' veya None (ikisi birden)."""
    import pyreadstat
    p2022 = KOK / "veri_seti" / "nsch_2022_topical_Stata" / "nsch_2022e_topical.dta"
    p2023 = KOK / "veri_seti" / "nsch_2023e_topical_Stata" / "nsch_2023e_topical.dta"

    if yil == '2022':
        df, _ = pyreadstat.read_dta(str(p2022))
        return df
    if yil == '2023':
        df, _ = pyreadstat.read_dta(str(p2023))
        return df
    df_22, _ = pyreadstat.read_dta(str(p2022))
    df_23, _ = pyreadstat.read_dta(str(p2023))
    return pd.concat([df_22, df_23], ignore_index=True)


def feature_engineering(df: pd.DataFrame) -> pd.DataFrame:
    """Ham NSCH sutunlarindan model ozelliklerini turetir."""
    tum_sutunlar = HAM_SUTUNLAR + list(KLINIK_HEDEF.values())
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

    return df_model


def hedef_olustur(df_model: pd.DataFrame) -> pd.DataFrame:
    """Klinik hedef sutunlarini ekler (1 -> 1, 2 -> 0)."""
    for ad, col in KLINIK_HEDEF.items():
        if col in df_model.columns:
            df_model[f'{ad}_hedef'] = df_model[col].map({1: 1, 2: 0})
    hedef_sutunlari = [f'{ad}_hedef' for ad in KLINIK_HEDEF if f'{ad}_hedef' in df_model.columns]
    df_model['genel_risk_hedef'] = df_model[hedef_sutunlari].max(axis=1)
    return df_model


def hedef_kolonu(model_ad: str) -> str:
    if model_ad == 'genel_risk':
        return 'genel_risk_hedef'
    return f'{model_ad}_hedef'


def best_params_yukle() -> dict:
    """optimizasyon_sonuc.json'dan her model icin best_params'i okur."""
    p = KOK / "optimizasyon_sonuc.json"
    with open(p, 'r', encoding='utf-8') as f:
        data = json.load(f)
    return {ad: m['best_params'] for ad, m in data.items()}


def optimal_threshold(y_true: np.ndarray, y_proba: np.ndarray) -> float:
    """F1'i maksimize eden threshold."""
    from sklearn.metrics import precision_recall_curve
    p, r, t = precision_recall_curve(y_true, y_proba)
    f1 = np.array([2 * pi * ri / (pi + ri) if (pi + ri) > 0 else 0
                   for pi, ri in zip(p[:-1], r[:-1])])
    return float(t[int(np.argmax(f1))])


# =========================================================================
# Yasam tarzi risk hesabi — risk_engine.py'deki ile birebir ayni mantik
# ama agirliklar PARAMETRE (Analiz 5 icin)
# =========================================================================

# NSCH kategori -> saat donusumleri (codebook 2022/2023)
# Frekans dogrulamasi: hoursleep (6-17) mode=4 (8h, %35), hoursleep05 (0-5) mode=7 (12+h)
NSCH_UYKU_SAAT_6_17 = {1: 5.5, 2: 6.0, 3: 7.0, 4: 8.0, 5: 9.0, 6: 10.0, 7: 11.5}
NSCH_UYKU_SAAT_0_5 = {1: 6.5, 2: 7.0, 3: 8.0, 4: 9.0, 5: 10.0, 6: 11.0, 7: 12.5}

# screentime: 1=<1h, 2=1h, 3=2h, 4=3h, 5=4+h
NSCH_SCREENTIME_SAAT = {1: 0.5, 2: 1.0, 3: 2.0, 4: 3.0, 5: 4.5}

# physactiv: 1=0 gun, 2=1-3 gun, 3=4-6 gun, 4=7 gun -> risk_engine seviyesi (0/1/2)
NSCH_PHYSACTIV_SEVIYE = {1: 0, 2: 1, 3: 2, 4: 2}


def uyku_saat_donustur(df: pd.DataFrame) -> pd.Series:
    """NSCH hoursleep/hoursleep05 KATEGORILERINI saate cevirir.

    NSCH'de bu sutunlar saat degil 1-7 arasi kategorik kodlardir ve
    yas grubuna gore farkli mapping'leri vardir:
      - Yas 6-17: hoursleep (1=<6h, 4=8h, 7=11+h)
      - Yas 0-5:  hoursleep05 (1=<7h, 4=9h, 7=12+h)
    """
    yas = pd.to_numeric(df['sc_age_years'], errors='coerce')
    hl = pd.to_numeric(df['hoursleep'], errors='coerce')
    hl05 = pd.to_numeric(df['hoursleep05'], errors='coerce')

    saat = pd.Series(np.nan, index=df.index, dtype=float)
    mask_old = (yas >= 6) & hl.notna()
    saat.loc[mask_old] = hl.loc[mask_old].map(NSCH_UYKU_SAAT_6_17)
    mask_young = saat.isna() & hl05.notna()
    saat.loc[mask_young] = hl05.loc[mask_young].map(NSCH_UYKU_SAAT_0_5)
    return saat


EKRAN_KILAVUZ = {
    (0, 1): 0,
    (2, 5): 1,
    (6, 12): 2,
    (13, 17): 3,
}

UYKU_KILAVUZ = {
    (0, 1): (12, 16),
    (1, 2): (11, 14),
    (3, 5): (10, 13),
    (6, 12): (9, 12),
    (13, 17): (8, 10),
}


def risk_komponentleri(yas: int, uyku_saati: float, ekran_saati: float,
                        fiziksel_aktivite: int) -> tuple[float, float, float]:
    """3 yasam tarzi risk komponentini ayri ayri dondurur (her biri 0-100).

    risk_engine.yasam_tarzi_riski_hesapla ile ayni mantik, ama agirliklamayi
    yapmaz - komponentler kendi degerleriyle dondurulur.
    """
    max_ekran = 3
    for (alt, ust), sinir in EKRAN_KILAVUZ.items():
        if alt <= yas <= ust:
            max_ekran = sinir
            break
    if ekran_saati <= max_ekran:
        ekran_risk = 0.0
    else:
        asim = ekran_saati - max_ekran
        yas_carpani = 1.5 if yas <= 5 else (1.2 if yas <= 12 else 1.0)
        ekran_risk = min(100.0, asim * 20 * yas_carpani)

    min_uyku, max_uyku = 8, 10
    for (alt, ust), (mn, mx) in UYKU_KILAVUZ.items():
        if alt <= yas <= ust:
            min_uyku, max_uyku = mn, mx
            break
    if min_uyku <= uyku_saati <= max_uyku:
        uyku_risk = 0.0
    elif uyku_saati < min_uyku:
        uyku_risk = min(100.0, (min_uyku - uyku_saati) * 25)
    else:
        uyku_risk = min(100.0, (uyku_saati - max_uyku) * 10)

    aktivite_risk = float({0: 80, 1: 30, 2: 0}.get(fiziksel_aktivite, 30))

    return ekran_risk, uyku_risk, aktivite_risk


def yasam_tarzi_risk_param(yas: int, uyku_saati: float, ekran_saati: float,
                            fiziksel_aktivite: int,
                            w_ekran: float = 0.30,
                            w_uyku: float = 0.26,
                            w_aktivite: float = 0.44) -> float:
    """risk_engine.yasam_tarzi_riski_hesapla'nin agirliklari parametrik versiyonu."""
    ekran_risk, uyku_risk, aktivite_risk = risk_komponentleri(
        yas, uyku_saati, ekran_saati, fiziksel_aktivite
    )
    return ekran_risk * w_ekran + uyku_risk * w_uyku + aktivite_risk * w_aktivite


# Sonuc klasoru hazir tut
SONUC_DIR.mkdir(parents=True, exist_ok=True)
MODEL_2022_DIR.mkdir(parents=True, exist_ok=True)
(SONUC_DIR / "04_shap").mkdir(parents=True, exist_ok=True)
