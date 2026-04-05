import requests, json

def test(isim, veri):
    r = requests.post('http://127.0.0.1:8001/tahmin', json=veri)
    if r.status_code != 200:
        print(f'{isim}: HTTP {r.status_code} - {r.text[:200]}')
        return
    d = r.json()
    print(f'{isim}: risk={d["genel_risk_puani"]}, durum={d["analiz_sonucu"]}')
    print(f'  dikkat: {d["dikkat_gerektiren_alanlar"]}')

# Normal cocuk
test('Normal', {'yas': 8, 'cinsiyet': 0, 'boy_cm': 128, 'kilo_kg': 26,
    'ekran_saati': 2.0, 'uyku_saati': 9.0, 'fiziksel_aktivite': 1})

# Orta riskli
test('Riskli', {'yas': 8, 'cinsiyet': 0, 'boy_cm': 128, 'kilo_kg': 26,
    'ekran_saati': 5.0, 'uyku_saati': 6.0, 'fiziksel_aktivite': 0})

# Extreme
test('Extreme', {'yas': 8, 'cinsiyet': 0, 'boy_cm': 128, 'kilo_kg': 26,
    'ekran_saati': 8.0, 'uyku_saati': 4.0, 'fiziksel_aktivite': 0})
