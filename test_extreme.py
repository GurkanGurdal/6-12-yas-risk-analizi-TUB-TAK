import json, requests

# En kotu degerler
veri = {'yas': 8, 'cinsiyet': 0, 'boy_cm': 128, 'kilo_kg': 26,
        'ekran_saati': 8.0, 'uyku_saati': 4.0, 'fiziksel_aktivite': 0,
        'gunluk_su_litre': 0.3, 'ana_ogun': 1, 'ara_ogun': 0}
r = requests.post('http://localhost:8000/tahmin', json=veri)
d = r.json()
print('Genel Risk:', d['genel_risk_puani'], d['analiz_sonucu'])
print('Dikkat:', d['dikkat_gerektiren_alanlar'])
psi = d['katmanlar']['psikolojik']
for k in ['anksiyete', 'depresyon', 'dehb', 'davranis']:
    m = psi[k]
    print(f"  {k}: ek={m['ek_risk']}, mutlak={m['mutlak_risk']}%, temel={m['temel_risk']}%")
print(f"  psi_ek_ort: {psi['ek_risk_ortalama']}")
