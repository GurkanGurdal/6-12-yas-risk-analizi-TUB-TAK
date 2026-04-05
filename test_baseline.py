import json, requests

# Normal/kilavuza uygun cocuk (8 yas, erkek, 2h ekran, 9h uyku, orta aktivite)
veri = {
    'yas': 8, 'cinsiyet': 0, 'boy_cm': 128, 'kilo_kg': 26,
    'ekran_saati': 2.0, 'uyku_saati': 9.0, 'fiziksel_aktivite': 1,
    'gunluk_su_litre': 1.0, 'ana_ogun': 3, 'ara_ogun': 2
}
r = requests.post('http://localhost:8000/tahmin', json=veri)
d = r.json()
print('=== NORMAL COCUK (kilavuza uygun) ===')
print(f"Genel Risk: {d['genel_risk_puani']}")
print(f"Durum: {d['analiz_sonucu']}")
psi = d['katmanlar']['psikolojik']
print(f"Psikolojik ek_risk_ort: {psi['ek_risk_ortalama']}")
print(f"  Anksiyete ek: {psi['anksiyete']['ek_risk']}, mutlak: {psi['anksiyete']['mutlak_risk']}, temel: {psi['anksiyete']['temel_risk']}")
print(f"  Depresyon ek: {psi['depresyon']['ek_risk']}, mutlak: {psi['depresyon']['mutlak_risk']}, temel: {psi['depresyon']['temel_risk']}")
print(f"  DEHB ek: {psi['dehb']['ek_risk']}, mutlak: {psi['dehb']['mutlak_risk']}, temel: {psi['dehb']['temel_risk']}")
print(f"  Davranis ek: {psi['davranis']['ek_risk']}, mutlak: {psi['davranis']['mutlak_risk']}, temel: {psi['davranis']['temel_risk']}")
yt = d['katmanlar']['yasam_tarzi']
print(f"Yasam Tarzi: risk={yt['risk_puani']}, ekran={yt['ekran_risk']}, uyku={yt['uyku_risk']}, aktivite={yt['aktivite_risk']}")
print()

# Riskli cocuk (8 yas, 5h ekran, 6h uyku, 0 aktivite)
veri2 = {
    'yas': 8, 'cinsiyet': 0, 'boy_cm': 128, 'kilo_kg': 26,
    'ekran_saati': 5.0, 'uyku_saati': 6.0, 'fiziksel_aktivite': 0,
    'gunluk_su_litre': 0.5, 'ana_ogun': 2, 'ara_ogun': 1
}
r2 = requests.post('http://localhost:8000/tahmin', json=veri2)
d2 = r2.json()
print('=== RISKLI COCUK ===')
print(f"Genel Risk: {d2['genel_risk_puani']}")
print(f"Durum: {d2['analiz_sonucu']}")
psi2 = d2['katmanlar']['psikolojik']
print(f"Psikolojik ek_risk_ort: {psi2['ek_risk_ortalama']}")
print(f"  Anksiyete ek: {psi2['anksiyete']['ek_risk']}, mutlak: {psi2['anksiyete']['mutlak_risk']}, temel: {psi2['anksiyete']['temel_risk']}")
print(f"  Depresyon ek: {psi2['depresyon']['ek_risk']}, mutlak: {psi2['depresyon']['mutlak_risk']}, temel: {psi2['depresyon']['temel_risk']}")
print(f"  DEHB ek: {psi2['dehb']['ek_risk']}, mutlak: {psi2['dehb']['mutlak_risk']}, temel: {psi2['dehb']['temel_risk']}")
print(f"  Davranis ek: {psi2['davranis']['ek_risk']}, mutlak: {psi2['davranis']['mutlak_risk']}, temel: {psi2['davranis']['temel_risk']}")
yt2 = d2['katmanlar']['yasam_tarzi']
print(f"Yasam Tarzi: risk={yt2['risk_puani']}, ekran={yt2['ekran_risk']}, uyku={yt2['uyku_risk']}, aktivite={yt2['aktivite_risk']}")
