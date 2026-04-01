"""Değişkenlerin etiket kodlamalarını öğren."""
import pyreadstat

df, meta = pyreadstat.read_dta(
    r"veri_seti\nsch_2023e_topical_Stata\nsch_2023e_topical.dta"
)

# Kritik değişkenlerin label'larını yazdır
target_vars = ['k2q01', 'screentime', 'hoursleep', 'hoursleep05',
               'physactiv', 'bmiclass', 'bedtime', 'outdoorswkday', 'outdoorswkend',
               'k2q33a', 'k2q32a', 'k2q31a']

for var in target_vars:
    if var in meta.variable_value_labels:
        labels = meta.variable_value_labels[var]
        print(f"\n{var} ({meta.column_names_to_labels.get(var, '?')}):")
        for k, v in sorted(labels.items()):
            print(f"  {k}: {v}")
    else:
        print(f"\n{var}: No labels found (continuous or unlabeled)")
