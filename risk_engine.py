"""
Çok Boyutlu Çocuk Gelişim Risk Motoru — V3 (NSCH Klinik Modeller)

Yapı:
├── Genel Risk (bileşik klinik model) ─── nsch_genel_risk_model.pkl
├── Psikolojik Alt Dallar:
│   ├── Anksiyete ─── nsch_anksiyete_model.pkl
│   ├── Depresyon ─── nsch_depresyon_model.pkl
│   └── DEHB ─── nsch_dehb_model.pkl
├── Gelişimsel Alt Dallar:
│   ├── Davranış Bozukluğu ─── nsch_davranis_model.pkl
│   └── Gelişim Gecikmesi ─── nsch_gelisim_gecikmesi_model.pkl
└── Fiziksel Gelişim ─── WHO Z-score (growth_norms.py)

Tüm modeller NSCH verisinden eğitilmiş, sadece Flutter girdileriyle çalışır.
"""

import numpy as np
import pandas as pd
import joblib
from growth_norms import fiziksel_gelisim_riski


class NSCHRiskMotoru:
    """NSCH verisinden eğitilmiş tüm modelleri yönetir."""

    MODEL_ISIMLERI = {
        'genel_risk': 'Genel Risk',
        'anksiyete': 'Anksiyete Riski',
        'depresyon': 'Depresyon Riski',
        'dehb': 'DEHB Riski',
        'davranis': 'Davranış Bozukluğu Riski',
        'gelisim_gecikmesi': 'Gelişim Gecikmesi Riski',
    }

    def __init__(self):
        self.ozellikler = joblib.load('nsch_ozellikler.pkl')
        self.modeller = {}
        for ad in self.MODEL_ISIMLERI:
            self.modeller[ad] = joblib.load(f'nsch_{ad}_model.pkl')

    def kullanici_girdisini_hazirla(
        self,
        yas: int,
        cinsiyet: int,       # 0=Erkek, 1=Kadın
        uyku_saati: float,
        ekran_saati: float,
        boy_cm: float,
        kilo_kg: float,
        fiziksel_aktivite: int,  # 0=Düşük, 1=Orta, 2=Yüksek
        dis_mekan_dk_hafta_ici: float = None,
        dis_mekan_dk_hafta_sonu: float = None,
    ) -> pd.DataFrame:
        """Flutter girdilerini NSCH model formatına dönüştürür."""

        nsch_cinsiyet = cinsiyet + 1

        # Ekran → NSCH kategorik
        if ekran_saati < 1:     nsch_ekran = 1
        elif ekran_saati < 2:   nsch_ekran = 2
        elif ekran_saati < 3:   nsch_ekran = 3
        elif ekran_saati < 4:   nsch_ekran = 4
        else:                   nsch_ekran = 5

        nsch_uyku = max(1, min(7, round(uyku_saati)))

        aktivite_map = {0: 1, 1: 2, 2: 4}
        nsch_aktivite = aktivite_map.get(fiziksel_aktivite, 2)

        if uyku_saati >= 9:      nsch_bedtime = 1
        elif uyku_saati >= 7:    nsch_bedtime = 2
        elif uyku_saati >= 5:    nsch_bedtime = 3
        else:                    nsch_bedtime = 4

        bmi = kilo_kg / ((boy_cm / 100) ** 2) if boy_cm > 0 else np.nan

        if yas <= 12:
            if bmi < 15:     bmi_class = 1
            elif bmi < 22:   bmi_class = 2
            elif bmi < 25:   bmi_class = 3
            else:            bmi_class = 4
        else:
            if bmi < 18.5:   bmi_class = 1
            elif bmi < 25:   bmi_class = 2
            elif bmi < 30:   bmi_class = 3
            else:            bmi_class = 4

        def dk_to_outdoor(dk):
            if dk is None:   return np.nan
            if dk < 15:      return 1
            elif dk < 30:    return 2
            elif dk < 60:    return 3
            elif dk < 120:   return 4
            else:            return 5

        nsch_outdoor_wk = dk_to_outdoor(dis_mekan_dk_hafta_ici)
        nsch_outdoor_we = dk_to_outdoor(dis_mekan_dk_hafta_sonu)

        if dis_mekan_dk_hafta_ici is not None or dis_mekan_dk_hafta_sonu is not None:
            hici = nsch_outdoor_wk if not np.isnan(nsch_outdoor_wk) else 0
            hsonu = nsch_outdoor_we if not np.isnan(nsch_outdoor_we) else 0
            dis_mekan_ort = (hici * 5 + hsonu * 2) / 7
        else:
            dis_mekan_ort = np.nan

        ekran_yas_orani = nsch_ekran / (yas + 1)
        ekran_uyku_orani = nsch_ekran / (nsch_uyku + 1)
        ekran_siddeti = nsch_ekran ** 2
        hareketsizlik = nsch_ekran / (nsch_aktivite + 1)

        ekran_dismekan_orani = np.nan
        if dis_mekan_ort is not None and not np.isnan(dis_mekan_ort) and dis_mekan_ort > 0:
            ekran_dismekan_orani = nsch_ekran / dis_mekan_ort

        veri = {
            'sc_age_years': yas,
            'sc_sex': nsch_cinsiyet,
            'screentime': nsch_ekran,
            'physactiv': nsch_aktivite,
            'bedtime': nsch_bedtime,
            'bmiclass': bmi_class,
            'height': boy_cm,
            'weight': kilo_kg,
            'outdoorswkday': nsch_outdoor_wk,
            'outdoorswkend': nsch_outdoor_we,
            'uyku': nsch_uyku,
            'bmi': bmi,
            'ekran_yas_orani': ekran_yas_orani,
            'ekran_uyku_orani': ekran_uyku_orani,
            'ekran_siddeti': ekran_siddeti,
            'hareketsizlik': hareketsizlik,
            'dis_mekan_ort': dis_mekan_ort,
            'ekran_dismekan_orani': ekran_dismekan_orani,
        }

        df = pd.DataFrame([veri])
        return df[self.ozellikler]

    def _ideal_girdi_olustur(self, yas: int, cinsiyet: int, boy_cm: float, kilo_kg: float) -> pd.DataFrame:
        """
        Aynı yaş/cinsiyet/boy/kilo ama KILAVUZA UYGUN yaşam alışkanlıkları
        olan çocuğun model girdisini oluşturur (baseline).
        
        Kılavuz-uyumlu (normal) değerler:
        - Ekran: ~2 saat (NSCH=3) — AAP 6-12 yaş sınırı
        - Uyku: 9 saat — CDC alt sınırı (6-12 yaş)
        - Fiziksel aktivite: Orta (NSCH=2, haftada 1-3 gün)
        - Düzenli uyku: Çoğunlukla düzenli (NSCH=2)
        - Dış mekan: Orta (NSCH=3)
        
        Bu sayede kılavuza uygun bir çocuk ~0 ek risk alır,
        gerçekten riskli olanlar fark gösterir.
        """
        nsch_cinsiyet = cinsiyet + 1
        bmi = kilo_kg / ((boy_cm / 100) ** 2) if boy_cm > 0 else np.nan

        if yas <= 12:
            if bmi < 15:     bmi_class = 1
            elif bmi < 22:   bmi_class = 2
            elif bmi < 25:   bmi_class = 3
            else:            bmi_class = 4
        else:
            if bmi < 18.5:   bmi_class = 1
            elif bmi < 25:   bmi_class = 2
            elif bmi < 30:   bmi_class = 3
            else:            bmi_class = 4

        # Kılavuz-uyumlu (normal) değerler
        ideal_ekran = 3       # ~2 saat (AAP kılavuz sınırı)
        ideal_uyku = 9        # CDC alt sınır (6-12 yaş)
        ideal_aktivite = 2    # Haftada 1-3 gün (orta düzey)
        ideal_bedtime = 2     # Çoğunlukla düzenli
        ideal_outdoor = 3     # Orta düzey dış mekan

        veri = {
            'sc_age_years': yas,
            'sc_sex': nsch_cinsiyet,
            'screentime': ideal_ekran,
            'physactiv': ideal_aktivite,
            'bedtime': ideal_bedtime,
            'bmiclass': bmi_class,
            'height': boy_cm,
            'weight': kilo_kg,
            'outdoorswkday': ideal_outdoor,
            'outdoorswkend': ideal_outdoor,
            'uyku': ideal_uyku,
            'bmi': bmi,
            'ekran_yas_orani': ideal_ekran / (yas + 1),
            'ekran_uyku_orani': ideal_ekran / (ideal_uyku + 1),
            'ekran_siddeti': ideal_ekran ** 2,
            'hareketsizlik': ideal_ekran / (ideal_aktivite + 1),
            'dis_mekan_ort': ideal_outdoor,
            'ekran_dismekan_orani': ideal_ekran / ideal_outdoor,
        }

        df = pd.DataFrame([veri])
        return df[self.ozellikler]

    def tum_riskleri_hesapla(
        self,
        df_input: pd.DataFrame,
        yas: int,
        cinsiyet: int,
        boy_cm: float,
        kilo_kg: float,
    ) -> dict:
        """
        GÖRELİ RİSK hesaplar: Kullanıcının girdilerinin riski ne kadar ARTIRDIĞI.
        
        Yöntem:
        1. Gerçek girdilerle → mutlak risk
        2. Aynı yaş/cinsiyet/boy/kilo ama KILAVUZA UYGUN alışkanlıklarla → temel risk
        3. Ek risk = (gerçek - temel) farkı (yüzde puan)
           → 0 = kılavuza uygun, pozitif = riskli, negatif = idealden iyi
        """
        # İdeal (baseline) girdi oluştur
        df_ideal = self._ideal_girdi_olustur(yas, cinsiyet, boy_cm, kilo_kg)

        sonuclar = {}
        for ad, model in self.modeller.items():
            # Gerçek risk
            gercek_proba = float(model.predict_proba(df_input)[0][1])
            # İdeal (baseline) risk
            ideal_proba = float(model.predict_proba(df_ideal)[0][1])

            # Ek risk hesabı: basit fark (kılavuz baseline ile)
            ek_risk = (gercek_proba - ideal_proba) * 100
            # Negatif = baseline'dan daha iyi → 0 say
            ek_risk = max(0, min(100, ek_risk))

            sonuclar[ad] = {
                'ek_risk': round(ek_risk, 2),
                'mutlak_risk': round(gercek_proba * 100, 2),
                'temel_risk': round(ideal_proba * 100, 2),
            }

        return sonuclar


# ==============================================================================
# YAŞAM TARZI RİSK DEĞERLENDİRMESİ (AAP/CDC Kılavuzlarına dayalı)
# ==============================================================================

# AAP Ekran Süresi Kılavuzu (yaşa göre max saat/gün)
EKRAN_KILAVUZ = {
    (0, 1): 0,      # 0-1 yaş: ekran yok
    (2, 5): 1,      # 2-5 yaş: max 1 saat
    (6, 12): 2,     # 6-12 yaş: max 2 saat
    (13, 17): 3,    # 13-17 yaş: max 3 saat (genel öneri)
}

# CDC/AAP Uyku Kılavuzu (yaşa göre minimum saat)
UYKU_KILAVUZ = {
    (0, 1): (12, 16),
    (1, 2): (11, 14),
    (3, 5): (10, 13),
    (6, 12): (9, 12),
    (13, 17): (8, 10),
}


def yasam_tarzi_riski_hesapla(
    yas: int,
    uyku_saati: float,
    ekran_saati: float,
    fiziksel_aktivite: int,  # 0=Düşük, 1=Orta, 2=Yüksek
) -> dict:
    """
    AAP/CDC kılavuzlarına göre yaşam tarzı risk skoru hesaplar.
    
    Bu fonksiyon ML modelinden BAĞIMSIZ çalışır.
    Amacı: "5 saat ekran + 5 saat uyku + düşük aktivite" gibi
    durumları ML modeli yakalayamasa bile doğru şekilde cezalandırmak.
    """
    detaylar = []

    # --- EKRAN SÜRESİ RİSKİ ---
    max_ekran = 3  # varsayılan
    for (alt, ust), sinir in EKRAN_KILAVUZ.items():
        if alt <= yas <= ust:
            max_ekran = sinir
            break

    if ekran_saati <= max_ekran:
        ekran_risk = 0
        detaylar.append(f"Ekran süresi uygun (≤{max_ekran}h)")
    else:
        asim = ekran_saati - max_ekran
        # Yaş çarpanı: küçük yaşta aşım daha riskli
        yas_carpani = 1.5 if yas <= 5 else (1.2 if yas <= 12 else 1.0)
        ekran_risk = min(100, asim * 20 * yas_carpani)
        detaylar.append(f"Ekran {asim:.0f}h fazla (max {max_ekran}h)")

    # --- UYKU RİSKİ ---
    min_uyku, max_uyku = 8, 10  # varsayılan
    for (alt, ust), (mn, mx) in UYKU_KILAVUZ.items():
        if alt <= yas <= ust:
            min_uyku, max_uyku = mn, mx
            break

    if min_uyku <= uyku_saati <= max_uyku:
        uyku_risk = 0
        detaylar.append(f"Uyku süresi uygun ({min_uyku}-{max_uyku}h)")
    elif uyku_saati < min_uyku:
        eksik = min_uyku - uyku_saati
        uyku_risk = min(100, eksik * 25)  # Her 1 saat eksik = 25 puan
        detaylar.append(f"Uyku {eksik:.0f}h eksik (min {min_uyku}h)")
    else:
        fazla = uyku_saati - max_uyku
        uyku_risk = min(100, fazla * 10)
        detaylar.append(f"Uyku {fazla:.0f}h fazla (max {max_uyku}h)")

    # --- FİZİKSEL AKTİVİTE RİSKİ ---
    aktivite_risk_map = {0: 80, 1: 30, 2: 0}  # Düşük=80, Orta=30, Yüksek=0
    aktivite_risk = aktivite_risk_map.get(fiziksel_aktivite, 30)
    if fiziksel_aktivite == 0:
        detaylar.append("Fiziksel aktivite çok düşük")
    elif fiziksel_aktivite == 1:
        detaylar.append("Fiziksel aktivite orta düzey")
    else:
        detaylar.append("Fiziksel aktivite yeterli")

    # Birleşik yaşam tarzı risk skoru
    # Ağırlıklar veriden türetilmiştir (Analiz 7, NSCH 2022+2023, n=66464):
    # standardize logistic regression risk komponentleri üzerinde,
    # 7 outcome (k2q01 + 5 psikolojik tanı + any_psych) ortalaması.
    toplam = ekran_risk * 0.30 + uyku_risk * 0.26 + aktivite_risk * 0.44

    return {
        "risk_puani": round(toplam, 2),
        "ekran_risk": round(ekran_risk, 2),
        "uyku_risk": round(uyku_risk, 2),
        "aktivite_risk": round(aktivite_risk, 2),
        "detaylar": "; ".join(detaylar),
    }


def birlesik_risk_hesapla(
    ml_skorlar: dict,
    fiziksel_risk: float,
    yasam_tarzi_risk: float,
) -> dict:
    """
    Tüm riskleri birleştirip final skoru üretir.
    
    Yapı (3 katman — direkt toplam):
    - Psikolojik (anksiyete, depresyon, DEHB, davranış)
    - Yaşam Tarzı (AAP/CDC kılavuzları)
    - Fiziksel Gelişim (WHO Z-score + gelişim gecikmesi)
    
    Yöntem: Katmanlar direkt toplanır, üst sınır yok.
    Teorik max: ~300 (her katman 0-100).
    """
    def ek(ad):
        return ml_skorlar.get(ad, {}).get('ek_risk', 0)

    # Psikolojik katman: 4 model (davranış dahil)
    psi_skorlar = {
        'anksiyete': ek('anksiyete'),
        'depresyon': ek('depresyon'),
        'dehb': ek('dehb'),
        'davranis': ek('davranis'),
    }
    psikolojik_ort = sum(psi_skorlar.values()) / len(psi_skorlar)

    # Fiziksel katman: WHO Z-score + gelişim gecikmesi
    gelisim_gec = ek('gelisim_gecikmesi')
    fiziksel_birlesik = fiziksel_risk * 0.6 + gelisim_gec * 0.4

    # Direkt toplam — üst sınır yok
    final = max(0, psikolojik_ort + yasam_tarzi_risk + fiziksel_birlesik)

    # Eşikler popülasyon dağılımı (NSCH 2023, n=31448) ve k2q01 dış doğrulama
    # ortalamalarıyla kalibre edildi (Analiz 6: Excellent=41, Very Good=53,
    # Good=65, Fair=73, Poor=79). Gerçek popülasyon dağılımı:
    # Çok Düşük %40, Düşük %19, Orta %16, Yüksek %12, Çok Yüksek %13.
    if final >= 80:
        durum, renk = "Çok Yüksek Risk / Kırmızı Bölge", "#CC0000"
    elif final >= 65:
        durum, renk = "Yüksek Risk / Kırmızı Bölge", "#FF4444"
    elif final >= 50:
        durum, renk = "Orta Risk / Sarı Bölge", "#FFAA00"
    elif final >= 35:
        durum, renk = "Düşük Risk / Yeşil Bölge", "#44BB44"
    else:
        durum, renk = "Çok Düşük Risk / Yeşil Bölge", "#00CC00"

    dikkat = []
    if yasam_tarzi_risk >= 50:
        dikkat.append("Yaşam Tarzı (Yüksek)")
    elif yasam_tarzi_risk >= 25:
        dikkat.append("Yaşam Tarzı (Orta)")

    # Psikolojik modeller: ek_risk ile kontrol (yeni skala: basit fark)
    # ek_risk ≥10 → Yüksek, ≥3 → Orta (eski normalize skaladan farklı)
    for ad in ['anksiyete', 'depresyon', 'dehb', 'davranis']:
        e_risk = ek(ad)
        isim = NSCHRiskMotoru.MODEL_ISIMLERI.get(ad, ad)
        if e_risk >= 10:
            dikkat.append(f"{isim} (Yüksek)")
        elif e_risk >= 3:
            dikkat.append(f"{isim} (Orta)")

    # Gelişim gecikmesi
    gelisim_mutlak = ml_skorlar.get('gelisim_gecikmesi', {}).get('mutlak_risk', 0)
    if gelisim_gec >= 10 or gelisim_mutlak >= 30:
        dikkat.append("Gelişim Gecikmesi (Yüksek)")
    elif gelisim_gec >= 3 or gelisim_mutlak >= 15:
        dikkat.append("Gelişim Gecikmesi (Orta)")

    if fiziksel_risk >= 50:
        dikkat.append("Fiziksel Gelişim (Yüksek)")
    elif fiziksel_risk >= 25:
        dikkat.append("Fiziksel Gelişim (Orta)")

    return {
        "genel_risk_puani": round(final, 2),
        "analiz_sonucu": durum,
        "grafik_rengi": renk,
        "dikkat_gerektiren_alanlar": dikkat,
    }

