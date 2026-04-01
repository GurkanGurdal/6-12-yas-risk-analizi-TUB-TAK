"""NSCH klinik modelleriyle entegrasyon testi — Göreli Risk."""
import json, sys
sys.path.insert(0, '.')
from app import tahmin_et, KullaniciVerisi

def test(ad, v):
    r = tahmin_et(v)
    print(f"  Genel Risk: {r['genel_risk_puani']} → {r['analiz_sonucu']}")
    ml = r['katmanlar']['genel_risk_ml']
    print(f"  ML Genel: ek_risk={ml['ek_risk']}, mutlak={ml['mutlak_risk']}, temel={ml['temel_risk']}")
    psi = r['katmanlar']['psikolojik']
    print(f"  Psikolojik (ek risk ort): {psi['ek_risk_ortalama']}")
    print(f"    Ank: ek={psi['anksiyete']['ek_risk']}, Dep: ek={psi['depresyon']['ek_risk']}, DEHB: ek={psi['dehb']['ek_risk']}")
    yt = r['katmanlar']['yasam_tarzi']
    print(f"  Yaşam Tarzı: {yt['risk_puani']} ({yt['detaylar']})")
    print(f"  Fiziksel: {r['katmanlar']['fiziksel_gelisim']['risk_puani']}")
    print(f"  Dikkat: {r['dikkat_gerektiren_alanlar']}")
    return r

print("=" * 60)
print("TEST 1: 10 yaşında 190cm 70kg — anormal boy, ama iyi alışkanlıklar")
print("=" * 60)
r1 = test("t1", KullaniciVerisi(
    yas=10, cinsiyet=0, uyku_saati=9, ekran_saati=2,
    boy_cm=190, kilo_kg=70, fiziksel_aktivite=2,
    dis_mekan_dk_hafta_ici=60, dis_mekan_dk_hafta_sonu=90
))
print()

print("=" * 60)
print("TEST 2: 8 yaş, 5 saat uyku, 5 saat ekran, düşük aktivite")
print("=" * 60)
r2 = test("t2", KullaniciVerisi(
    yas=8, cinsiyet=1, uyku_saati=5, ekran_saati=5,
    boy_cm=128, kilo_kg=26, fiziksel_aktivite=0,
    dis_mekan_dk_hafta_ici=10, dis_mekan_dk_hafta_sonu=20
))
print()

print("=" * 60)
print("TEST 3: Sağlıklı çocuk (10 yaş, her şey ideal)")
print("=" * 60)
r3 = test("t3", KullaniciVerisi(
    yas=10, cinsiyet=0, uyku_saati=10, ekran_saati=1,
    boy_cm=140, kilo_kg=33, fiziksel_aktivite=2,
    dis_mekan_dk_hafta_ici=90, dis_mekan_dk_hafta_sonu=120
))
print()

print("=" * 60)
print("TEST 4: 15 yaş, 8h ekran, 4h uyku, obez, düşük aktivite")
print("=" * 60)
r4 = test("t4", KullaniciVerisi(
    yas=15, cinsiyet=0, uyku_saati=4, ekran_saati=8,
    boy_cm=170, kilo_kg=95, fiziksel_aktivite=0,
    dis_mekan_dk_hafta_ici=0, dis_mekan_dk_hafta_sonu=10
))
print()

print("=" * 60)
print("KARŞILAŞTIRMA")
print("=" * 60)
print(f"  Test2 (kötü alışkanlık, 8yaş): {r2['genel_risk_puani']} → {r2['analiz_sonucu']}")
print(f"  Test3 (ideal alışkanlık, 10yaş): {r3['genel_risk_puani']} → {r3['analiz_sonucu']}")
print(f"  Test2 > Test3 mi? {'✅ DOĞRU' if r2['genel_risk_puani'] > r3['genel_risk_puani'] else '❌ YANLIŞ'}")

results = {"test1": r1, "test2": r2, "test3": r3, "test4": r4}
with open("test_results_nsch.json", "w", encoding="utf-8") as f:
    json.dump(results, f, indent=2, ensure_ascii=False)
print("\nSonuçlar test_results_nsch.json'a kaydedildi.")
