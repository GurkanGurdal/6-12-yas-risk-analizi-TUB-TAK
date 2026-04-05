from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from pydantic import BaseModel
from typing import Optional

from risk_engine import NSCHRiskMotoru, yasam_tarzi_riski_hesapla, birlesik_risk_hesapla
from growth_norms import fiziksel_gelisim_riski

app = FastAPI(title="Zeka Katmanları - Çocuk Gelişim Risk Analiz Servisi")

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

risk_motoru = NSCHRiskMotoru()


@app.get("/")
def health_check():
    return {"status": "ok", "service": "Çocuk Gelişim Risk Analiz API"}


class KullaniciVerisi(BaseModel):
    yas: int
    cinsiyet: int                               # 0: Erkek, 1: Kadın
    uyku_saati: float
    ekran_saati: float
    boy_cm: float
    kilo_kg: float
    fiziksel_aktivite: int                      # 0: Düşük, 1: Orta, 2: Yüksek
    dis_mekan_dk_hafta_ici: Optional[float] = None
    dis_mekan_dk_hafta_sonu: Optional[float] = None


@app.post("/tahmin")
def tahmin_et(veriler: KullaniciVerisi):
    """
    Çok boyutlu çocuk gelişim risk analizi.
    
    Tüm ML sonuçları GÖRELİ RİSK olarak raporlanır:
    "Bu çocuğun yaşam alışkanlıkları, yaşıtlarına göre riski ne kadar artırıyor?"
    """

    # A. NSCH Klinik Modeller (6 model — göreli risk)
    df_input = risk_motoru.kullanici_girdisini_hazirla(
        yas=veriler.yas,
        cinsiyet=veriler.cinsiyet,
        uyku_saati=veriler.uyku_saati,
        ekran_saati=veriler.ekran_saati,
        boy_cm=veriler.boy_cm,
        kilo_kg=veriler.kilo_kg,
        fiziksel_aktivite=veriler.fiziksel_aktivite,
        dis_mekan_dk_hafta_ici=veriler.dis_mekan_dk_hafta_ici,
        dis_mekan_dk_hafta_sonu=veriler.dis_mekan_dk_hafta_sonu,
    )
    ml_skorlar = risk_motoru.tum_riskleri_hesapla(
        df_input,
        yas=veriler.yas,
        cinsiyet=veriler.cinsiyet,
        boy_cm=veriler.boy_cm,
        kilo_kg=veriler.kilo_kg,
    )

    # B. Yaşam Tarzı Risk (AAP/CDC kılavuzları)
    yasam = yasam_tarzi_riski_hesapla(
        yas=veriler.yas,
        uyku_saati=veriler.uyku_saati,
        ekran_saati=veriler.ekran_saati,
        fiziksel_aktivite=veriler.fiziksel_aktivite,
    )

    # C. Fiziksel Gelişim (WHO Z-Score)
    fiziksel = fiziksel_gelisim_riski(
        veriler.yas, veriler.cinsiyet,
        veriler.boy_cm, veriler.kilo_kg
    )

    # D. Birleşik Risk
    genel = birlesik_risk_hesapla(
        ml_skorlar=ml_skorlar,
        fiziksel_risk=fiziksel["risk_puani"],
        yasam_tarzi_risk=yasam["risk_puani"],
    )

    return {
        "genel_risk_puani": genel["genel_risk_puani"],
        "analiz_sonucu": genel["analiz_sonucu"],
        "grafik_rengi": genel["grafik_rengi"],
        "dikkat_gerektiren_alanlar": genel["dikkat_gerektiren_alanlar"],

        "katmanlar": {
            "genel_risk_ml": {
                "ek_risk": ml_skorlar["genel_risk"]["ek_risk"],
                "mutlak_risk": ml_skorlar["genel_risk"]["mutlak_risk"],
                "temel_risk": ml_skorlar["genel_risk"]["temel_risk"],
                "agirlik": "30%",
                "kaynak": "NSCH bileşik klinik model (göreli risk)",
            },
            "psikolojik": {
                "anksiyete": ml_skorlar["anksiyete"],
                "depresyon": ml_skorlar["depresyon"],
                "dehb": ml_skorlar["dehb"],
                "ek_risk_ortalama": round(
                    (ml_skorlar["anksiyete"]["ek_risk"] +
                     ml_skorlar["depresyon"]["ek_risk"] +
                     ml_skorlar["dehb"]["ek_risk"]) / 3, 2
                ),
                "agirlik": "20%",
            },
            "yasam_tarzi": {
                "risk_puani": yasam["risk_puani"],
                "ekran_risk": yasam["ekran_risk"],
                "uyku_risk": yasam["uyku_risk"],
                "aktivite_risk": yasam["aktivite_risk"],
                "agirlik": "30%",
                "kaynak": "AAP/CDC kılavuzları",
                "detaylar": yasam["detaylar"],
            },
            "gelisimsel": {
                "davranis_bozuklugu": ml_skorlar["davranis"],
                "gelisim_gecikmesi": ml_skorlar["gelisim_gecikmesi"],
            },
            "fiziksel_gelisim": {
                "risk_puani": fiziksel["risk_puani"],
                "agirlik": "20%",
                "boy_zscore": fiziksel["boy_zscore"],
                "kilo_zscore": fiziksel["kilo_zscore"],
                "bmi_zscore": fiziksel["bmi_zscore"],
                "hesaplanan_bmi": fiziksel["hesaplanan_bmi"],
                "detaylar": fiziksel["detaylar"],
            },
        },
    }