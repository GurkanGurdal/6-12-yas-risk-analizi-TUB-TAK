"""NSCH veri setini keşfet — değişken sayısı, kayıt sayısı, hedef değişkenler."""
import pyreadstat
import json

# 2023 verisini oku
df, meta = pyreadstat.read_dta(
    r"veri_seti\nsch_2023e_topical_Stata\nsch_2023e_topical.dta"
)
print(f"2023 Kayit sayisi: {len(df)}, Degisken sayisi: {len(df.columns)}")

# Kritik değişkenleri incele
kritik = [
    'sc_age_years', 'sc_sex', 'bmiclass', 'height', 'weight',
    'hoursleep', 'hoursleep05', 'screentime', 'physactiv',
    'k2q01',  # General Health
    'k2q33a', 'k2q33b',  # Anxiety
    'k2q32a', 'k2q32b',  # Depression
    'k2q31a', 'k2q31b',  # ADHD
    'outdoorswkday', 'outdoorswkend',
    'bedtime',
]

info = {}
for col in kritik:
    if col in df.columns:
        info[col] = {
            'dtype': str(df[col].dtype),
            'non_null': int(df[col].notna().sum()),
            'null_count': int(df[col].isna().sum()),
            'unique': int(df[col].nunique()),
            'value_counts': {str(k): int(v) for k, v in df[col].value_counts().head(10).items()},
        }
        # Label bilgisi varsa ekle
        if col in meta.column_names_to_labels:
            info[col]['label'] = meta.column_names_to_labels[col]
    else:
        info[col] = 'NOT FOUND'

with open('data_explore.json', 'w', encoding='utf-8') as f:
    json.dump(info, f, indent=2, ensure_ascii=False)
print("Sonuclar data_explore.json dosyasina kaydedildi")
