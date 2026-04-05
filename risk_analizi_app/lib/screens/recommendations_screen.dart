import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_neumorphic_plus/flutter_neumorphic.dart';

import '../core/responsive.dart';
import '../core/theme.dart';

// ─── Veri Modeli ───

class _Category {
  final IconData icon;
  final String title;
  final Color color;
  final List<String> tips;

  const _Category({
    required this.icon,
    required this.title,
    required this.color,
    required this.tips,
  });
}

const _categories = <_Category>[
  _Category(
    icon: Icons.phone_android_rounded,
    title: 'Ekran Süresini\nAzaltma',
    color: AppTheme.riskRed,
    tips: [
      'Çocuğunuzun yemek saatlerinde ve yatmadan en az 1 saat önce ekranları kapatmasını sağlayın.',
      'Evde "ekransız bölgeler" belirleyin; örneğin yatak odası ve yemek masası ekran kullanılmayan alanlar olsun.',
      'Çocuğunuzla birlikte günlük ekran süresi limiti koyun ve bu limiti görünür bir yere asın.',
      'Ekran yerine geçecek alternatif aktiviteler önerin: kitap okuma, bulmaca, lego, resim yapma gibi.',
      'Ekran süresini ödül olarak kullanmaktan kaçının; bu alışkanlığı daha cazip hale getirir.',
      'Kendiniz de ekran kullanımınızı azaltarak çocuğunuza rol model olun.',
      'Ekran süresini bir anda kesmek yerine haftalık 15-20 dakika azaltarak kademeli olarak düşürün.',
      'Çocuğunuzun izlediği/oynadığı içerikleri birlikte seçin ve kaliteli içeriklere yönlendirin.',
    ],
  ),
  _Category(
    icon: Icons.bedtime_rounded,
    title: 'Uyku Süresini\nArtırma',
    color: AppTheme.primaryBlue,
    tips: [
      'Çocuğunuz için sabit bir yatma ve uyanma saati belirleyin; hafta sonları da buna uyun.',
      'Yatmadan 1 saat önce sakinleştirici bir rutin oluşturun: ılık duş, kitap okuma, hafif müzik.',
      'Yatak odasının karanlık, serin ve sessiz olmasını sağlayın.',
      'Çocuğunuzun yatmadan 2-3 saat önce kafeinli içecek (çay, kola, çikolata) tüketmemesine dikkat edin.',
      'Yatağı sadece uyku için kullanmasını sağlayın; yatakta tablet veya telefon kullanmayı yasaklayın.',
      'Çocuğunuzun gün içinde yeterli fiziksel aktivite yapmasını sağlayın; bu gece uykusunu derinleştirir.',
      'Akşam yemeğini yatma saatinden en az 2 saat önce yedirin; aşırı tok veya aç uyumaktan kaçının.',
      'Çocuğunuzun uyku ihtiyacını yaşına göre takip edin (okul çağı: 9-12 saat, ergen: 8-10 saat).',
    ],
  ),
  _Category(
    icon: Icons.bedtime_off_rounded,
    title: 'Uyku Süresini\nAzaltma',
    color: Color(0xFF7C3AED),
    tips: [
      'Çocuğunuzun gündüz uykusunu kısaltın veya tamamen kaldırın (5 yaş üstüyse genellikle gerekmez).',
      'Sabah uyanma saatini 15-20 dakika öne çekerek kademeli olarak uyku süresini ayarlayın.',
      'Çocuğunuzun aşırı uyumasının bir sağlık sorunundan kaynaklanmadığından emin olun; gerekirse doktora danışın.',
      'Gün içinde daha fazla fiziksel ve zihinsel aktivite planlayın; hareketsizlik aşırı uykuya yol açabilir.',
      'Çocuğunuzun yaşı için önerilen uyku süresini kontrol edin; bazı çocuklar doğal olarak daha fazla uyur.',
      'Sabahları güneş ışığına maruz kalmasını sağlayın; bu biyolojik saati düzenlemeye yardımcı olur.',
    ],
  ),
  _Category(
    icon: Icons.directions_run_rounded,
    title: 'Fiziksel Aktiviteyi\nArtırma',
    color: AppTheme.riskGreen,
    tips: [
      'Çocuğunuzun günde en az 60 dakika orta-yoğun fiziksel aktivite yapmasını hedefleyin.',
      'Birlikte yapabileceğiniz aktiviteler planlayın: yürüyüş, bisiklet, top oyunları, park gezisi.',
      'Çocuğunuzun ilgi alanına göre bir spor dalına yönlendirin; zorlamak yerine denemesine izin verin.',
      'Okul sonrası "önce hareket, sonra ekran" kuralı koyun.',
      'Ev içinde de hareket fırsatları yaratın: dans etme, engel parkuru, ip atlama.',
      'Ailenizle hafta sonu doğa yürüyüşleri veya bisiklet turları organize edin.',
      'Çocuğunuzun arkadaşlarıyla dışarıda oynamasını teşvik edin; sosyal oyunlar motivasyonu artırır.',
      'Küçük hedefler koyun ve başarıları kutlayın; örneğin "bu hafta her gün 30 dakika dışarıda oynadık" gibi.',
    ],
  ),
  _Category(
    icon: Icons.trending_up_rounded,
    title: 'Kilo\nAlma',
    color: AppTheme.accentPeach,
    tips: [
      'Çocuğunuzun düzenli olarak günde 3 ana öğün ve 2-3 ara öğün yemesini sağlayın.',
      'Kalori yoğunluğu yüksek sağlıklı besinler tercih edin: avokado, kuruyemiş, tam yağlı süt ürünleri, zeytinyağı.',
      'Yemeklere peynir, tereyağı veya zeytinyağı ekleyerek kalori değerini artırın.',
      'Smoothie ve milkshake\'ler hazırlayın: süt, muz, fıstık ezmesi, yulaf karışımı besleyici olabilir.',
      'Çocuğunuzun yemek yeme motivasyonunu artırmak için yemekleri renkli ve eğlenceli sunun.',
      'Yemek saatlerini ekrandan uzak, aile ortamında geçirin; bu iştahı olumlu etkiler.',
      'Çocuk doktorunuzdan veya bir diyetisyenden destek alarak sağlıklı kilo alma planı oluşturun.',
      'Proteinden zengin besinler ekleyin: yumurta, tavuk, balık, baklagiller kas gelişimini destekler.',
    ],
  ),
  _Category(
    icon: Icons.trending_down_rounded,
    title: 'Kilo\nVerme',
    color: AppTheme.accentGold,
    tips: [
      'Çocuğunuza sıkı diyet uygulamak yerine sağlıklı beslenme alışkanlıkları kazandırmaya odaklanın.',
      'Evde hazır gıda, cipsi ve şekerli içecek bulundurmayın; bunların yerine meyve, sebze ve kuruyemiş bırakın.',
      'Porsiyon kontrolü yapın; büyük tabaklar yerine küçük tabaklar kullanın.',
      'Çocuğunuzun su tüketimini artırın; şekerli içecekler yerine su veya ayranı tercih edin.',
      'Birlikte yemek hazırlayın; bu hem eğlenceli bir aktivite hem de sağlıklı beslenme farkındalığı yaratır.',
      'Fiziksel aktiviteyi günlük rutinin doğal bir parçası haline getirin; yürüyerek okula gitme, merdiven kullanma gibi.',
      'Kilo konusunu çocuğunuzun önünde olumsuz bir dille ele almayın; sağlıklı ve güçlü olmaya odaklanın.',
      'Bir çocuk doktoru veya diyetisyenle görüşerek çocuğunuzun yaşına ve boyuna uygun sağlıklı kilo aralığını öğrenin.',
    ],
  ),
];

// ─── Ana Sayfa: Grid ───

class RecommendationsScreen extends StatelessWidget {
  const RecommendationsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final r = Responsive(context);
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: ListView(
        padding: r.pagePadding(horizontal: 20, top: 8, bottom: 120),
        children: [
          // Başlık
          Neumorphic(
            style: AppTheme.nConvex(radius: r.scale(16)),
            padding: EdgeInsets.all(r.scale(18)),
            child: Row(
              children: [
                Neumorphic(
                  style: AppTheme.nConcave(radius: r.scale(14)),
                  padding: EdgeInsets.all(r.scale(10)),
                  child: Icon(Icons.lightbulb_rounded, color: AppTheme.riskYellow, size: r.scale(26)),
                ),
                SizedBox(width: r.scale(14)),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Öneriler',
                        style: TextStyle(
                          fontSize: r.scale(20),
                          fontWeight: FontWeight.w800,
                          color: AppTheme.textDark,
                        ),
                      ),
                      SizedBox(height: r.scale(4)),
                      Text(
                        'Çocuğunuz için sağlıklı yaşam önerileri',
                        style: TextStyle(
                          fontSize: r.scale(12),
                          color: AppTheme.textGray,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          SizedBox(height: r.scale(18)),

          // 2'li grid
          for (int i = 0; i < _categories.length; i += 2)
            Padding(
              padding: EdgeInsets.only(bottom: r.scale(14)),
              child: Row(
                children: [
                  Expanded(child: _GridCard(category: _categories[i])),
                  SizedBox(width: r.scale(14)),
                  Expanded(
                    child: i + 1 < _categories.length
                        ? _GridCard(category: _categories[i + 1])
                        : const SizedBox.shrink(),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

// ─── Grid Kart ───

class _GridCard extends StatelessWidget {
  final _Category category;
  const _GridCard({required this.category});

  @override
  Widget build(BuildContext context) {
    final r = Responsive(context);
    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => _DetailPage(category: category)),
      ),
      child: Neumorphic(
        style: AppTheme.nFlat(radius: r.scale(18)),
        padding: EdgeInsets.symmetric(vertical: r.scale(20), horizontal: r.scale(14)),
        child: Column(
          children: [
            SizedBox(
              width: r.scale(52),
              height: r.scale(52),
              child: Neumorphic(
                style: AppTheme.nConcave(radius: r.scale(16)),
                child: Center(
                  child: Icon(category.icon, color: category.color, size: r.scale(28)),
                ),
              ),
            ),
            SizedBox(height: r.scale(12)),
            Text(
              category.title,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: r.scale(13),
                fontWeight: FontWeight.w700,
                color: AppTheme.textDark,
                height: 1.3,
              ),
            ),
            SizedBox(height: r.scale(6)),
            Text(
              '${category.tips.length} öneri',
              style: TextStyle(
                fontSize: r.scale(11),
                color: AppTheme.textGray,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Detay Sayfası ───

class _DetailPage extends StatelessWidget {
  final _Category category;
  const _DetailPage({required this.category});

  @override
  Widget build(BuildContext context) {
    final r = Responsive(context);
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.dark,
        systemNavigationBarColor: AppTheme.nBase,
        systemNavigationBarIconBrightness: Brightness.dark,
      ),
      child: Scaffold(
        backgroundColor: AppTheme.nBase,
        body: SafeArea(
          child: Column(
            children: [
              // Üst bar
              Padding(
                padding: EdgeInsets.symmetric(horizontal: r.scale(12), vertical: r.scale(8)),
                child: Row(
                  children: [
                    NeumorphicButton(
                      style: AppTheme.nFlat(radius: r.scale(14)),
                      padding: EdgeInsets.all(r.scale(10)),
                      onPressed: () => Navigator.pop(context),
                      child: Icon(Icons.arrow_back_rounded, color: AppTheme.textDark, size: r.scale(22)),
                    ),
                    SizedBox(width: r.scale(12)),
                    Expanded(
                      child: Text(
                        category.title.replaceAll('\n', ' '),
                        style: TextStyle(
                          fontSize: r.scale(18),
                          fontWeight: FontWeight.w800,
                          color: AppTheme.textDark,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // İçerik
              Expanded(
                child: ListView(
                  padding: EdgeInsets.fromLTRB(r.scale(20), r.scale(8), r.scale(20), r.scale(32)),
                  children: [
                    // Üst ikon kartı
                    Center(
                      child: Neumorphic(
                        style: AppTheme.nConvex(radius: r.scale(20)),
                        padding: EdgeInsets.all(r.scale(22)),
                        child: SizedBox(
                          width: r.scale(64),
                          height: r.scale(64),
                          child: Neumorphic(
                            style: AppTheme.nConcave(radius: r.scale(20)),
                            child: Center(
                              child: Icon(category.icon, color: category.color, size: r.scale(36)),
                            ),
                          ),
                        ),
                      ),
                    ),
                    SizedBox(height: r.scale(20)),

                    // Öneri kartları
                    ...List.generate(category.tips.length, (i) {
                      return Padding(
                        padding: EdgeInsets.only(bottom: r.scale(12)),
                        child: Neumorphic(
                          style: AppTheme.nFlat(radius: r.scale(14)),
                          padding: EdgeInsets.all(r.scale(16)),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              SizedBox(
                                width: r.scale(28),
                                height: r.scale(28),
                                child: Neumorphic(
                                  style: AppTheme.nConcave(radius: r.scale(8)),
                                  child: Center(
                                    child: Text(
                                      '${i + 1}',
                                      style: TextStyle(
                                        fontSize: r.scale(13),
                                        fontWeight: FontWeight.w800,
                                        color: category.color,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                              SizedBox(width: r.scale(12)),
                              Expanded(
                                child: Text(
                                  category.tips[i],
                                  style: TextStyle(
                                    fontSize: r.scale(13.5),
                                    height: 1.55,
                                    color: AppTheme.textDark.withOpacity(0.88),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    }),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
