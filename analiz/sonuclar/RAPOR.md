# Makale Oncesi Analizler — Sonuc Raporu

Bu rapor 6 analiz scriptinin ciktisindan otomatik uretilmistir.
Detaylar icin `analiz/sonuclar/` altindaki JSON dosyalarina ve PNG figurlere bakin.

## Tablo 1 — Temporal Validasyon Performansi (%95 Bootstrap CI)

Egitim: NSCH 2022 | Test: NSCH 2023 (held-out yil)

| Model | n_test | AUC | F1 | Recall | Precision |
|-------|-------:|-----|----|--------|-----------|
| anksiyete | 54851 | 0.788 (0.783–0.793) | 0.378 (0.369–0.387) | 0.573 (0.561–0.586) | 0.282 (0.274–0.290) |
| depresyon | 54921 | 0.870 (0.865–0.876) | 0.341 (0.328–0.354) | 0.477 (0.460–0.494) | 0.266 (0.254–0.277) |
| dehb | 54749 | 0.774 (0.769–0.780) | 0.326 (0.318–0.334) | 0.561 (0.547–0.573) | 0.230 (0.223–0.237) |
| davranis | 55052 | 0.749 (0.743–0.756) | 0.280 (0.270–0.290) | 0.438 (0.424–0.452) | 0.206 (0.198–0.214) |
| gelisim_gecikmesi | 54906 | 0.677 (0.668–0.685) | 0.231 (0.222–0.240) | 0.378 (0.364–0.392) | 0.166 (0.159–0.174) |
| genel_risk | 55162 | 0.730 (0.725–0.734) | 0.486 (0.480–0.492) | 0.722 (0.714–0.729) | 0.366 (0.360–0.372) |

**Random-split (eski yontemle) vs Temporal (yeni) AUC karsilastirmasi:**

| Model | Random AUC | Temporal AUC | Fark |
|-------|-----------:|-------------:|-----:|
| anksiyete | 0.7857 | 0.7880 | +0.0023 |
| depresyon | 0.8680 | 0.8705 | +0.0025 |
| dehb | 0.7735 | 0.7744 | +0.0009 |
| davranis | 0.7550 | 0.7494 | -0.0056 |
| gelisim_gecikmesi | 0.6694 | 0.6768 | +0.0074 |
| genel_risk | 0.7359 | 0.7299 | -0.0060 |

## Tablo 2 — Kalibrasyon (Brier Score)

Sigmoid kalibrasyonun Brier skoru ne kadar dusurdugu (kucuk = daha iyi).

| Model | Brier (Ham) | Brier (Kalibre) | Iyilesme % |
|-------|------------:|----------------:|-----------:|
| anksiyete | 0.18591 | 0.09332 | +49.80% |
| depresyon | 0.15166 | 0.04302 | +71.63% |
| dehb | 0.19535 | 0.08422 | +56.89% |
| davranis | 0.19649 | 0.07047 | +64.13% |
| gelisim_gecikmesi | 0.21733 | 0.06864 | +68.42% |
| genel_risk | 0.20516 | 0.15883 | +22.58% |

![Reliability Diagram](sonuclar/reliability_grid.png)

## Tablo 3 — SHAP Top 5 Feature (her model)

- **anksiyete**: `sc_age_years` (0.651), `physactiv` (0.230), `hareketsizlik` (0.181), `height` (0.135), `ekran_uyku_orani` (0.126)
- **depresyon**: `sc_age_years` (1.527), `hareketsizlik` (0.304), `ekran_uyku_orani` (0.145), `bedtime` (0.141), `weight` (0.120)
- **dehb**: `sc_age_years` (0.867), `sc_sex` (0.335), `physactiv` (0.241), `ekran_uyku_orani` (0.133), `hareketsizlik` (0.130)
- **davranis**: `sc_sex` (0.442), `sc_age_years` (0.418), `hareketsizlik` (0.156), `bedtime` (0.119), `height` (0.116)
- **gelisim_gecikmesi**: `sc_sex` (0.368), `height` (0.144), `physactiv` (0.103), `bmi` (0.092), `sc_age_years` (0.090)
- **genel_risk**: `sc_age_years` (0.453), `hareketsizlik` (0.218), `sc_sex` (0.191), `ekran_uyku_orani` (0.088), `bedtime` (0.082)

**Figurler:**

- anksiyete: [summary](sonuclar/04_shap/anksiyete_summary.png) | [bar](sonuclar/04_shap/anksiyete_bar.png)
- depresyon: [summary](sonuclar/04_shap/depresyon_summary.png) | [bar](sonuclar/04_shap/depresyon_bar.png)
- dehb: [summary](sonuclar/04_shap/dehb_summary.png) | [bar](sonuclar/04_shap/dehb_bar.png)
- davranis: [summary](sonuclar/04_shap/davranis_summary.png) | [bar](sonuclar/04_shap/davranis_bar.png)
- gelisim_gecikmesi: [summary](sonuclar/04_shap/gelisim_gecikmesi_summary.png) | [bar](sonuclar/04_shap/gelisim_gecikmesi_bar.png)
- genel_risk: [summary](sonuclar/04_shap/genel_risk_summary.png) | [bar](sonuclar/04_shap/genel_risk_bar.png)

## Tablo 4 — Yasam Tarzi Agirliklarinin Veriden Turetilmesi

Mevcut tasarim agirliklari (ekran=0.40, uyku=0.35, aktivite=0.25) NSCH 2022+2023 verisinde standardize logistic regression ile dogrulandi.

**Iki yontem:**
- **Yontem A (ham):** Ham predictor'lar (ekran_saat, uyku_saat, aktivite_gun)
- **Yontem B (risk komponent):** risk_engine komponentleri (uyku U-sekli duzeltilmis)

| Bilesen | Orijinal (eski) | Yontem A | Yontem B (final) |
|---------|----------------:|---------:|-----------------:|
| ekran | 0.400 | 0.381 | **0.303** |
| uyku | 0.350 | 0.175 | **0.262** |
| aktivite | 0.250 | 0.444 | **0.435** |

**Final:** Yontem B onerilir — ONEMLI FARK: max fark 0.185. Agirliklar veri-bazli degerlere guncellenebilir.

**Uretim guncellemesi:** risk_engine.py:325 ekran=0.30, uyku=0.26, aktivite=0.44 (ham: ekran=0.3032, uyku=0.2622, aktivite=0.4346)

![Agirlik Karsilastirma](sonuclar/07_agirlik_karsilastirma.png)

## Tablo 5 — Yasam Tarzi Agirliklarinin Duyarlilik Analizi

Yeni veri-bazli baseline (0.30, 0.26, 0.44) +/-10pp perturbasyonlar.

**Agirlik kaynagi:** Veri-bazli (Analiz 7): NSCH 2022+2023 (n=66464) standardize logistic regression risk komponentleri uzerinde, 7 outcome ortalamasi
**Orneklem:** 32899 cocuk (NSCH 2023)

| Varyant | Agirliklar | Spearman rho | Kategori degisim % | |delta_skor| ort |
|---------|-----------|-------------:|-------------------:|----------------:|
| ekrana_kayma | (0.40, 0.16, 0.44) | 0.9951 | 8.06% | 1.547 |
| uykuya_kayma | (0.20, 0.36, 0.44) | 0.9798 | 1.10% | 1.547 |
| aktiviteye_kayma | (0.20, 0.26, 0.54) | 0.9777 | 0.94% | 1.876 |

**Yorum:** Spearman rho > 0.95 ve kategori degisim < %5 ise sistem 'robust' kabul edilir.

![Sensitivity Dagilim](sonuclar/sensitivity_dagilim.png)

## Tablo 6 — Birlesik Skorun Dis Dogrulamasi (k2q01)

- **n** = 31448
- **Spearman rho** = 0.2670 (95% CI: 0.2561–0.2772)
- **p-value** = 0.00e+00
- **Yorum**: Anlamli pozitif korelasyon (yuksek risk = kotu saglik)

**k2q01 kategorisine gore ortalama birlesik skor:**

| k2q01 | Aciklama | n | Mean skor | Std |
|------:|----------|--:|----------:|----:|
| 1 | Excellent | 19866 | 40.72 | 25.33 |
| 2 | Very Good | 8541 | 52.99 | 29.19 |
| 3 | Good | 2588 | 64.97 | 32.42 |
| 4 | Fair | 408 | 72.51 | 33.67 |
| 5 | Poor | 45 | 79.13 | 36.69 |

![Spearman Scatter](sonuclar/06_spearman_scatter.png)
