# Zeka Katmanları - Çocuk Gelişim Risk Analizi
**Yapay Zeka (AI) ve Karar Destek Sistemi - Geliştirme Raporu**

Bu döküman, mobil cihazdan elde edilebilen kısıtlı "yaşam tarzı" (ekran süresi, uyku, fiziksel aktivite vb.) verilerini kullanarak çocuklardaki klinik, psikolojik ve genel gelişimsel riskleri tespit etmek amacıyla geliştirilen hibrit yapay zeka sisteminin geliştirme adımlarını, kararlarını ve performans metriklerini özetlemektedir.

---

## 1. Veri Seti Seçimi ve Hazırlık
Projenin temel amacı olan "çocuk sağlığı ve yaşam tarzı etkileri" konusunda en güvenilir sonuçları elde edebilmek için, HRSA (Health Resources and Services Administration) ve MCHB (Maternal and Child Health Bureau) tarafından yürütülen dünyanın önde gelen çalışmalarından **NSCH (National Survey of Children's Health) 2022 ve 2023** veri setleri kullanılmıştır. 
* İki yıllık veri birleştirilerek **~110.000 satırlık** geniş ve güvenilir bir veri havuzu elde edilmiştir.

## 2. Mobil Odaklı Kısıtlamalar ve Özellik Mühendisliği (Feature Engineering)
NSCH binlerce sütun veriye sahip olsa da, bu projenin temel bir kısıtı vardır: **Bilgiler, çocuğun veya ebeveynin kullanacağı mobil/Flutter uygulamasından toplanacaktır.**
Kan tahlili, detaylı psikolojik formlar yerine mobil cihazın elde edebileceği özelliklere (features) odaklanılmıştır:
* **Temel Özellikler:** Yaş, Cinsiyet, Boy, Kilo (BMI).
* **Yaşam Tarzı:** Ekran Süresi, Uyku Saati, Fiziksel Aktivite Düzeyi, Dış Mekan (Açık hava) Süresi.

Salt bu özelliklerin, tanıları doğrudan tahmin etmekte zayıf kalabileceği tespit edilmiş ve veri setinden **yeni özellikler (Feature Engineering)** üretilmiştir:
* `ekran_uyku_orani` = Ekran Süresi / Uyku Süresi 
* `hareketsizlik_indeksi` = Ekran Süresi / Fiziksel Aktivite 
* `ekran_yas_orani` = Çocuğun yaşına oranla maruz kaldığı günlük ekran yükü.

## 3. Hedef Değişkenlerin  (Labels) Belirlenmesi
Ebeveynlerin subjektif "Çocuğumun sağlığı çok iyi" gibi yorumları yerine, doğrudan **doktor tanısı (klinik veri)** öngörüsü yapılmasına karar verildi. Makine öğrenmesi modeli için ikili sınıflandırma (Binary Classification) yapılacak şu 5 temel klinik tanı seçildi:
1. **Anksiyete** (k2q33a)
2. **Depresyon** (k2q32a)
3. **DEHB - Hiperaktivite** (k2q31a)
4. **Davranış Bozuklukları** (k2q34a)
5. **Gelişim Gecikmesi** (k2q36a)
6. Bunların tamamını kapsayan **Bileşik Genel Risk Modeli.**

## 4. Model Seçimi ve Öğrenme Sorunu (Dengesiz Veri)
Denemeler sonucunda tablosal (tabular) verilerde en iyi performansı gösteren, ağaç tabanlı **XGBoost (Extreme Gradient Boosting)** algoritması seçilmiştir.

Bu tür klinik verilerde büyük bir sorun vardır: Veri **çok dengesizdir**. *Örneğin: Her 100 çocuğun sadece 5'inde tanı konmuş depresyon vardır.* 
Modelin başarısını yalnızca %95 Accuracy (Doğruluk) üzerinden ölçmek, riskli çocukları es geçmesine yol açacaktır. Bu nedenle `scale_pos_weight` tekniği ile azınlıktaki (riskli) sınıfın model gözündeki ağırlığı artırılmıştır. Böylece model sadece sağlıklı çocukları ezberlemekten kurtulmuştur.

## 5. Göreli Risk Yaklaşımı (Relative / Excess Risk)
Klasik Makine Öğrenmesi modelleri yaşa ve cinsiyete göre güçlü bir "hastalık sıklığı" ezberler (Prevalence Bias). *Örn: 15 yaşındaki bir çocuğun dehb olma ihtimali, 5 yaşındakine göre doğal yollarla daha yüksektir.*
Bizim amacımız ise "yaş riskini" değil **"kullanıcının kendi tercihlerinin yarattığı riski"** puanlamaktır.

Bunun için algoritmada **"Göreli Risk (Excess Risk)"** metoduna geçilmiştir:
1. Çocuğun mevcut yaş/cinsiyet ve yaşam tarzı ile tahmin olasılığı hesaplanır (*Mutlak Risk*).
2. Aynı çocuk için **ideal yaşam koşullarındaki** (Uygun ekran, maksimum dış mekan, harika uyku) verisiyle bir taban tahmin oluşturulur (*Temel Risk*).
3. Sonuç kullanıcıya ulaştırılırken: Yaş faktörü tamamen elenir, ve "Bu çocuğun alışkanlıkları, kendi yaşıtlarındaki risk potansiyelini ne kadar ARTIRDI (Ek Risk)?" formülü hesaplanarak sonuç sunulur.

## 6. Uzman Sistemi ve 4 Katmanlı Hibrit Risk Motoru
Makine öğrenmesi algoritmaları yalnızca ellerindeki istatistiğe bakar, kural bilmez. "Günde 8 saat ekran, 4 saat uyku" makine öğrenmesi için sadece bir satırdır, tehlike olduğunu anlamayabilir.
Bu nedenle sistemin kalbine sadece Makine Öğrenmesi (ML) değil, klinik kanıtlara dayalı kural setleri (Expert System) de yerleştirilmiştir.
* **Yaşam Tarzı Etkisi (Ekran & Uyku Zararları):** Amerikan Pediatri Akademisi (AAP) ve CDC (Hastalık Kontrol Merkezi) kılavuzlarındaki ekran ve uyku yaş sınırları programlanmış, kılavuz aşılırsa ML riskinden bağımsız olarak kırmızı alarm üretilmesi sağlanmıştır.
* **Fiziksel Gelişim ve Obezite Riski (WHO/CDC):** Sadece klinik ML yetmezliği değil, çocuğun boy ve kilosu CDC/WHO'ya ait "Z-Score Growth Charts" (LMS Yöntemi) standartlarıyla analiz edilir. Bu sayede **Obezite, aşırı zayıflık veya boy kısalığı (bodurluk)** gibi teşhisler matematiksel bir kesinlikle (Z-score) hesaplanarak risk motoruna eklenmiştir.

**Final değerlendirmesi 4 Ana Katmanda hesaplanır:**
1. ML Bileşik Klinik Risk *(%30 Ağırlık)*
2. ML Psikolojik Alt Dal Riskleri *(%20 Ağırlık)*
3. AAP/CDC Yaşam Tarzı Ceza Puanı *(%30 Ağırlık)*
4. Büyüme Normları: Fiziksel Gelişim & Obezite *(%20 Ağırlık)*

## 7. Model Optimizasyonu ve Performans Sonuçları (Optuna)
Modellerin son halinde, standart parametreler yerine **Optuna** kütüphanesi kullanılarak hiperparametre optimizasyonuna (Hemen her model için 50'şer x 5 Cross Validation toplam 1500+ eğitim denemesi) gidilmiştir. Hedef fonksiyon olarak Accuracy (Doğruluk) yerine Recall (Riskliyi kaçırmama) ve ROC-AUC'yi dengeleyen bir optimizasyon sağlanmıştır.

Çıktı olasılıklarının (probabilities) insan seviyesindeki "gerçek hata paylarına" oturması için **CalibratedClassifierCV (Sigmoid kalibrasyonu)** kullanılmıştır.

### Güncel Optimizasyon Sonrası Performans Tablosu (Test Verisi)
Aşağıdaki değerler, yalnızca "Flutter girdileri" (sosyal/genetik veri olmadan) ile ulaşılan final başarı kriterleridir:

| Tahmin Edilen Teşhis | ROC-AUC Skoru | Recall (%) | Yorumlama |
| :--- | :--- | :--- | :--- |
| **Depresyon** | **0.86** | %44.7 | Oldukça başarılı, hayat tarzıyla depresyon son derece korele çıkmıştır. Ekran>Uyku rasyosu en güçlü etkendir. |
| **Anksiyete** | **0.78** | %57.2 | Kabul edilebilir üzerinde bilimsel geçerlilik. Risk taşıyanların %57'si mobil girdilerle başarıyla izole edilmektedir. |
| **DEHB** | **0.77** | %50.4 | Özellikle fiziksel aktivite düşüklüğü ve kısa süreli dış mekan ile güçlü ilişkiler tespit edilmiştir. |
| **Davranış Bzk.** | **0.75** | %45.5 | Kabul edilebilir bir tarama metrisi. |
| **Gelişim Gecikmesi**| **0.66** | %36.5 | Daha zayıf. Gelişim genetik ağırlıklı olduğundan mobil girdilerle tahmini diğer klinik alanlara göre doğal olarak uzaktır. |
| **Tüm/Genel Risk**  | **0.73** | %69.5 | Yüksek Recall: Çocukta herhangi bir teşhis edilmemiş klinik risk varsa, model çocukların ~%70'inde "Yüksek Risk" uyarısını vermektedir. Başarılı bir Ön Tarama (Screening) seviyesine gelinmiştir. |

### Sonuç
Bu çalışma, sadece mobil anket/input verilerini alarak gerçeğe son derece yakın (AUC ~0.80 civarı), istatistik ve kural (Expert) sisteminin harmoni ile çalıştığı yenilikçi bir karar destek asistanı yaratmıştır. 
Uygulanan veri düzeltme, özellik mühendisliği (Feature Engineering), kalibrasyon ve göreli risk hesapları, modelin TÜBİTAK/Akademik standartlarda savunulabilirliğini tam olarak kanıtlamaktadır.
