import requests

veri = {'yas': 8, 'cinsiyet': 0, 'boy_cm': 128, 'kilo_kg': 26,
    'ekran_saati': 2.0, 'uyku_saati': 9.0, 'fiziksel_aktivite': 1}
r = requests.post('http://127.0.0.1:8000/tahmin', json=veri)
print('Status:', r.status_code)
print(r.text[:2000])
