"""
WHO/CDC Büyüme Eğrileri Referans Tabloları ve Z-Score Hesaplama

Çocukların boy, kilo ve BMI değerlerini yaş ve cinsiyete göre
standart büyüme eğrileriyle karşılaştırarak Z-score hesaplar.

Kaynak: CDC Growth Charts (2-20 yaş)
"""

# ==============================================================================
# CDC BOY-YAŞ REFERANS TABLOLARI (2-17 yaş, cm)
# Her yaş için: (medyan, standart_sapma)
# Cinsiyet: 0 = Erkek, 1 = Kadın
# ==============================================================================

BOY_REFERANS = {
    # Erkek (cinsiyet=0)
    0: {
        2:  (87.0, 3.5),
        3:  (95.5, 3.8),
        4:  (102.5, 4.1),
        5:  (109.0, 4.5),
        6:  (115.5, 4.9),
        7:  (121.9, 5.3),
        8:  (128.0, 5.6),
        9:  (133.5, 5.9),
        10: (138.5, 6.2),
        11: (143.5, 7.0),
        12: (149.0, 7.5),
        13: (156.0, 8.0),
        14: (163.5, 7.8),
        15: (170.0, 7.2),
        16: (173.5, 6.8),
        17: (175.5, 6.5),
    },
    # Kadın (cinsiyet=1)
    1: {
        2:  (85.5, 3.4),
        3:  (94.0, 3.7),
        4:  (101.0, 4.0),
        5:  (107.5, 4.4),
        6:  (114.0, 4.8),
        7:  (120.5, 5.2),
        8:  (126.5, 5.6),
        9:  (132.5, 6.0),
        10: (138.5, 6.5),
        11: (144.5, 6.8),
        12: (151.0, 6.5),
        13: (156.0, 6.0),
        14: (159.0, 5.8),
        15: (160.5, 5.6),
        16: (162.0, 5.5),
        17: (162.5, 5.4),
    }
}

# ==============================================================================
# CDC KİLO-YAŞ REFERANS TABLOLARI (2-17 yaş, kg)
# ==============================================================================

KILO_REFERANS = {
    0: {
        2:  (12.5, 1.5),
        3:  (14.5, 1.7),
        4:  (16.5, 2.0),
        5:  (18.5, 2.3),
        6:  (20.5, 2.8),
        7:  (23.0, 3.3),
        8:  (25.5, 3.8),
        9:  (28.5, 4.5),
        10: (32.0, 5.2),
        11: (36.0, 6.0),
        12: (40.0, 6.8),
        13: (45.5, 7.5),
        14: (51.0, 8.0),
        15: (56.5, 8.2),
        16: (61.0, 8.5),
        17: (64.5, 8.8),
    },
    1: {
        2:  (12.0, 1.4),
        3:  (14.0, 1.6),
        4:  (16.0, 2.0),
        5:  (18.0, 2.4),
        6:  (20.0, 2.8),
        7:  (22.5, 3.3),
        8:  (25.5, 4.0),
        9:  (29.0, 4.8),
        10: (33.0, 5.5),
        11: (37.5, 6.2),
        12: (42.0, 6.8),
        13: (46.0, 7.2),
        14: (49.5, 7.5),
        15: (52.0, 7.8),
        16: (53.5, 7.9),
        17: (54.5, 8.0),
    }
}

# ==============================================================================
# CDC BMI-YAŞ REFERANS TABLOLARI (2-17 yaş, kg/m²)
# ==============================================================================

BMI_REFERANS = {
    0: {
        2:  (16.5, 1.3),
        3:  (15.9, 1.2),
        4:  (15.6, 1.2),
        5:  (15.5, 1.3),
        6:  (15.4, 1.5),
        7:  (15.5, 1.7),
        8:  (15.8, 2.0),
        9:  (16.1, 2.2),
        10: (16.6, 2.5),
        11: (17.2, 2.7),
        12: (17.8, 2.9),
        13: (18.5, 3.0),
        14: (19.2, 3.1),
        15: (19.9, 3.2),
        16: (20.5, 3.2),
        17: (21.0, 3.3),
    },
    1: {
        2:  (16.3, 1.3),
        3:  (15.7, 1.2),
        4:  (15.4, 1.2),
        5:  (15.3, 1.3),
        6:  (15.3, 1.5),
        7:  (15.5, 1.7),
        8:  (15.8, 2.0),
        9:  (16.3, 2.3),
        10: (16.8, 2.5),
        11: (17.5, 2.7),
        12: (18.2, 2.9),
        13: (18.9, 3.0),
        14: (19.5, 3.0),
        15: (20.0, 3.1),
        16: (20.4, 3.1),
        17: (20.7, 3.1),
    }
}


def z_score_hesapla(deger: float, medyan: float, std: float) -> float:
    """Bir değerin Z-score'unu hesaplar."""
    if std == 0:
        return 0.0
    return (deger - medyan) / std


def boy_zscore(yas: int, cinsiyet: int, boy_cm: float) -> float:
    """
    Çocuğun boyunun yaş ve cinsiyete göre Z-score'unu hesaplar.
    
    Args:
        yas: Çocuğun yaşı (2-17)
        cinsiyet: 0=Erkek, 1=Kadın
        boy_cm: Boy (cm)
    
    Returns:
        Z-score değeri. |Z| > 2 ise ciddi sapma.
    """
    yas_clamp = max(2, min(17, yas))
    cinsiyet_key = min(1, max(0, cinsiyet))
    
    medyan, std = BOY_REFERANS[cinsiyet_key][yas_clamp]
    return z_score_hesapla(boy_cm, medyan, std)


def kilo_zscore(yas: int, cinsiyet: int, kilo_kg: float) -> float:
    """
    Çocuğun kilosunun yaş ve cinsiyete göre Z-score'unu hesaplar.
    """
    yas_clamp = max(2, min(17, yas))
    cinsiyet_key = min(1, max(0, cinsiyet))
    
    medyan, std = KILO_REFERANS[cinsiyet_key][yas_clamp]
    return z_score_hesapla(kilo_kg, medyan, std)


def bmi_zscore(yas: int, cinsiyet: int, bmi: float) -> float:
    """
    Çocuğun BMI'sinin yaş ve cinsiyete göre Z-score'unu hesaplar.
    """
    yas_clamp = max(2, min(17, yas))
    cinsiyet_key = min(1, max(0, cinsiyet))
    
    medyan, std = BMI_REFERANS[cinsiyet_key][yas_clamp]
    return z_score_hesapla(bmi, medyan, std)


def fiziksel_gelisim_riski(yas: int, cinsiyet: int, boy_cm: float, kilo_kg: float) -> dict:
    """
    Boy, kilo ve BMI Z-score'larından fiziksel gelişim risk puanı hesaplar.
    
    Returns:
        {
            "boy_zscore": float,
            "kilo_zscore": float,
            "bmi_zscore": float,
            "risk_puani": float (0-100),
            "detaylar": str
        }
    """
    bmi = kilo_kg / ((boy_cm / 100) ** 2)
    
    bz = boy_zscore(yas, cinsiyet, boy_cm)
    kz = kilo_zscore(yas, cinsiyet, kilo_kg)
    bmiz = bmi_zscore(yas, cinsiyet, bmi)
    
    # En yüksek mutlak sapma riski belirler
    max_abs_z = max(abs(bz), abs(kz), abs(bmiz))
    
    # Z-score'dan risk puanına dönüşüm:
    # |Z| <= 1.0  → 0-15 (Normal)
    # |Z| 1.0-2.0 → 15-50 (Orta)
    # |Z| 2.0-3.0 → 50-80 (Yüksek)
    # |Z| > 3.0   → 80-100 (Çok Yüksek)
    if max_abs_z <= 1.0:
        risk = max_abs_z * 15
    elif max_abs_z <= 2.0:
        risk = 15 + (max_abs_z - 1.0) * 35
    elif max_abs_z <= 3.0:
        risk = 50 + (max_abs_z - 2.0) * 30
    else:
        risk = min(100, 80 + (max_abs_z - 3.0) * 10)
    
    # Detay mesajı
    detaylar = []
    if abs(bz) > 2:
        yön = "çok uzun" if bz > 0 else "çok kısa"
        detaylar.append(f"Boy yaşına göre {yön} (Z={bz:.1f})")
    if abs(kz) > 2:
        yön = "çok kilolu" if kz > 0 else "çok zayıf"
        detaylar.append(f"Kilo yaşına göre {yön} (Z={kz:.1f})")
    if abs(bmiz) > 2:
        yön = "obez" if bmiz > 0 else "aşırı zayıf"
        detaylar.append(f"BMI yaşına göre {yön} (Z={bmiz:.1f})")
    
    if not detaylar:
        if max_abs_z > 1:
            detaylar.append("Fiziksel gelişim hafif sapma gösteriyor")
        else:
            detaylar.append("Fiziksel gelişim yaşına uygun")
    
    return {
        "boy_zscore": round(bz, 2),
        "kilo_zscore": round(kz, 2),
        "bmi_zscore": round(bmiz, 2),
        "hesaplanan_bmi": round(bmi, 2),
        "risk_puani": round(risk, 2),
        "detaylar": "; ".join(detaylar)
    }
