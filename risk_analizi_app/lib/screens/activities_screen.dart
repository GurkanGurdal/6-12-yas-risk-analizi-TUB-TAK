import 'package:flutter/material.dart';
import 'package:flutter_neumorphic_plus/flutter_neumorphic.dart';

import '../core/responsive.dart';
import '../core/theme.dart';

class ActivitiesScreen extends StatelessWidget {
  const ActivitiesScreen({super.key});

  static const _categories = [
    _Category(
      title: 'Hareket ve Spor',
      icon: Icons.directions_run_rounded,
      color: Color(0xFF10B981),
      activities: [
        _Activity(
          title: 'Engel Parkuru',
          icon: Icons.sports_gymnastics,
          ageRange: '3–10 yaş',
          duration: '20–30 dk',
          benefit: 'Motor becerileri, denge, koordinasyon ve problem çözme yeteneğini geliştirir. Çocuk engelleri aşarken vücudunu nasıl kullanacağını öğrenir.',
          steps: [
            'Evin içinde veya bahçede yastıklar, sandalyeler, kutular ve battaniyeler ile bir parkur kurun.',
            'Altından geçilecek, üstünden atlanacak ve etrafından dolanılacak istasyonlar belirleyin.',
            'Çocuğunuza parkuru gösterin ve ilk turu birlikte yapın.',
            'Kronometre tutarak her turda süresini kısaltmasını teşvik edin.',
            'Yeni engeller ekleyerek parkuru her seferinde farklılaştırın.',
          ],
        ),
        _Activity(
          title: 'Hayvan Taklidi Yürüyüşü',
          icon: Icons.pets,
          ageRange: '2–7 yaş',
          duration: '10–15 dk',
          benefit: 'Kaba motor becerilerini, yaratıcılığı ve hayal gücünü destekler. Farklı hareket kalıpları kasları güçlendirir.',
          steps: [
            '"Ayı yürüyüşü" ile başlayın: eller ve ayaklar yerde, kalça havada ilerleyin.',
            '"Yengeç yürüyüşü" yapın: sırt üstü pozisyonda eller ve ayaklarla geriye gidin.',
            '"Kurbağa zıplaması" deneyin: çömelin ve ileriye doğru zıplayın.',
            '"Flamingo duruşu" ile dengeyi test edin: tek ayakta 10\'a kadar sayın.',
            'Çocuğunuzdan yeni hayvan hareketleri icat etmesini isteyin.',
          ],
        ),
        _Activity(
          title: 'Balon Voleybolu',
          icon: Icons.sports_volleyball,
          ageRange: '3–12 yaş',
          duration: '15–20 dk',
          benefit: 'El-göz koordinasyonu, refleksler ve takım çalışması becerilerini geliştirir. Kapalı alanda güvenle oynanabilir.',
          steps: [
            'Bir balonu şişirin ve odanın ortasına bir ip veya kurdele gerin.',
            'Her iki tarafa bir oyuncu geçsin (siz ve çocuğunuz).',
            'Balonu yere düşürmeden karşı tarafa geçirin.',
            'Sadece baş ile, sadece tek elle gibi kurallar ekleyerek zorlaştırın.',
            'Kaç kez düşürmeden devam edebildiğinizi sayarak rekor kırmaya çalışın.',
          ],
        ),
      ],
    ),
    _Category(
      title: 'Yaratıcılık ve Sanat',
      icon: Icons.palette_rounded,
      color: Color(0xFFF59E0B),
      activities: [
        _Activity(
          title: 'Duygu Maskeleri',
          icon: Icons.theater_comedy,
          ageRange: '4–10 yaş',
          duration: '30–40 dk',
          benefit: 'Duygusal farkındalığı artırır, duyguları tanıma ve ifade etme becerisi kazandırır. İnce motor becerileri ve yaratıcılığı destekler.',
          steps: [
            'Karton tabaklar, keçeli kalemler, renkli kağıtlar ve yapıştırıcı hazırlayın.',
            'Her tabağa farklı bir duygu çizin: mutlu, üzgün, kızgın, şaşkın, korkmuş.',
            'Çocuğunuzla her duygunun ne zaman hissedildiğini konuşun.',
            'Maskeleri sıraya dizin ve "bugün nasıl hissediyorsun?" diye sorun.',
            'Maskeleri kullanarak kısa hikayeler veya canlandırmalar yapın.',
          ],
        ),
        _Activity(
          title: 'Doğa Kolajı',
          icon: Icons.eco,
          ageRange: '3–9 yaş',
          duration: '30–45 dk',
          benefit: 'Doğa gözlem becerisini geliştirir, ince motor kaslarını çalıştırır. Çocuğun çevresindeki güzellikleri fark etmesini sağlar.',
          steps: [
            'Bir poşet alıp bahçeye veya parka çıkın.',
            'Yapraklar, çiçekler, dallar, taşlar gibi doğal malzemeler toplayın.',
            'Eve dönünce büyük bir karton üzerine yapıştırıcıyla bir tablo oluşturun.',
            'Topladığı her malzemenin adını söylemesini ve nerede bulduğunu anlatmasını isteyin.',
            'Kolajı odanın duvarına asarak çocuğunuzun eserini değerli hissetmesini sağlayın.',
          ],
        ),
        _Activity(
          title: 'Hikaye Küpleri',
          icon: Icons.auto_stories,
          ageRange: '5–12 yaş',
          duration: '20–30 dk',
          benefit: 'Dil gelişimini, hayal gücünü ve hikaye anlatma becerisini güçlendirir. Sözcük dağarcığını zenginleştirir.',
          steps: [
            'Küp şeklinde kartonlar kesin veya mevcut zarları kullanın.',
            'Her yüzüne basit resimler çizin: güneş, ev, ağaç, araba, köpek, kalp vb.',
            'Küpleri atın ve gelen resimlere bakarak sırayla bir hikaye uydurun.',
            'Siz bir cümle söyleyin, çocuğunuz devam ettirsin.',
            'Hikayeyi kaydedin veya birlikte resimleyin.',
          ],
        ),
      ],
    ),
    _Category(
      title: 'Zihinsel Gelişim',
      icon: Icons.psychology_rounded,
      color: Color(0xFF6366F1),
      activities: [
        _Activity(
          title: 'Hazine Avı',
          icon: Icons.explore,
          ageRange: '4–10 yaş',
          duration: '20–30 dk',
          benefit: 'Problem çözme, yön bulma ve mantıksal düşünme yeteneklerini geliştirir. Okuma–yazma pratiği sağlar.',
          steps: [
            'Evin farklı köşelerine küçük ipuçları gizleyin (kağıt notlar).',
            'Her ipucu bir sonraki ipucunun yerini tarif etsin.',
            'Son ipucu küçük bir ödüle (sticker, meyve, küçük oyuncak) götürsün.',
            'İpuçlarını yaşa göre ayarlayın: küçükler için resimli, büyükler için bilmece şeklinde.',
            'Sonraki seferde çocuğunuzun sizin için hazine avı hazırlamasını isteyin.',
          ],
        ),
        _Activity(
          title: 'Hafıza Kartları',
          icon: Icons.grid_view_rounded,
          ageRange: '3–12 yaş',
          duration: '10–20 dk',
          benefit: 'Kısa süreli hafıza, konsantrasyon ve dikkat süresini güçlendirir. Eşleştirme becerisi kazandırır.',
          steps: [
            'Kartonları eşit boyutta kesin ve ikişerli eşleşen resimler çizin.',
            'Kartları ters çevirerek masaya dizin.',
            'Sırayla iki kart açın — eşleşirse alın, eşleşmezse kapatın.',
            'Küçük yaşlar için 6 çift, büyükler için 12-15 çift kullanın.',
            'En az hamle ile bitirmeyi hedefleyin.',
          ],
        ),
        _Activity(
          title: 'Sayı ve Renk Avı',
          icon: Icons.colorize,
          ageRange: '2–6 yaş',
          duration: '10–15 dk',
          benefit: 'Renk ve sayı tanıma, dikkat ve gözlem becerilerini geliştirir. Günlük yaşamı öğrenme fırsatına dönüştürür.',
          steps: [
            'Bir renk seçin (örn: kırmızı) ve evde o renkte kaç nesne bulunabilir sayın.',
            'Sonra bir sayı seçin ve o kadar nesne toplamasını isteyin.',
            'Dışarı çıkınca "mavi araba gördüm!" gibi renk gözlemi oyunu yapın.',
            'Her bulduğu nesne için alkışlayarak motivasyonu artırın.',
            'Zorluk ekleyin: "hem yuvarlak hem kırmızı bir şey bul!" gibi.',
          ],
        ),
      ],
    ),
    _Category(
      title: 'Duygusal Bağ Kurma',
      icon: Icons.favorite_rounded,
      color: Color(0xFFEF4444),
      activities: [
        _Activity(
          title: 'Günün En Güzel 3 Anı',
          icon: Icons.auto_awesome,
          ageRange: '4–12 yaş',
          duration: '5–10 dk',
          benefit: 'Olumlu düşünmeyi teşvik eder, ebeveyn–çocuk iletişimini güçlendirir. Çocuğun güne değer vermesini sağlar.',
          steps: [
            'Her akşam yatmadan önce birlikte yatağa oturun.',
            '"Bugün seni en çok ne mutlu etti?" diye sorun.',
            'Sırayla üçer güzel an paylaşın.',
            'Çocuğunuzun anlattıklarını dikkatle dinleyin ve sorular sorun.',
            'Bu rutini her gece tekrarlayarak alışkanlık haline getirin.',
          ],
        ),
        _Activity(
          title: 'Beraber Yemek Yapma',
          icon: Icons.restaurant,
          ageRange: '3–12 yaş',
          duration: '30–60 dk',
          benefit: 'İş birliği, sorumluluk duygusu ve matematik becerilerini (ölçme, sayma) geliştirir. Birlikte üretmenin mutluluğunu yaşatır.',
          steps: [
            'Basit bir tarif seçin: kurabiye, meyve salatası veya sandviç.',
            'Malzemeleri birlikte hazırlayın — çocuğunuza güvenli görevler verin.',
            'Ölçüleri birlikte okuyun: "2 bardak un gerekiyor, beraber ölçelim."',
            'Karıştırma, şekil verme gibi eğlenceli kısımları çocuğunuza bırakın.',
            'Birlikte yaptığınız yemeği aile ile paylaşarak başarı hissini pekiştirin.',
          ],
        ),
        _Activity(
          title: 'Duygu Günlüğü',
          icon: Icons.menu_book,
          ageRange: '5–12 yaş',
          duration: '10–15 dk',
          benefit: 'Duygusal zekayı geliştirir, kendini yazılı ifade etme becerisini güçlendirir. Stres ve kaygıyla başa çıkmayı öğretir.',
          steps: [
            'Güzel bir defter alın ve "Duygu Günlüğüm" diye kapağına yazın.',
            'Her gün bir duygu emoji\'si çizmesini isteyin (mutlu, üzgün, vb.).',
            'Yanına 1-2 cümle yazsın: "Bugün mutluydum çünkü..."',
            'Yazamayanlar için resim çizme seçeneği sunun.',
            'Haftada bir birlikte eski sayfaları okuyun ve duygusal değişimleri konuşun.',
          ],
        ),
      ],
    ),
    _Category(
      title: 'Uyku Öncesi Ritüel',
      icon: Icons.bedtime_rounded,
      color: Color(0xFF8B5CF6),
      activities: [
        _Activity(
          title: 'Nefes Egzersizi',
          icon: Icons.air,
          ageRange: '3–12 yaş',
          duration: '5 dk',
          benefit: 'Sinir sistemini sakinleştirir, uyku kalitesini artırır. Çocuğun stresle başa çıkma aracı geliştirmesini sağlar.',
          steps: [
            'Çocuğunuzla birlikte rahat bir pozisyonda oturun veya uzanın.',
            '"Çiçek koklama": burnundan 4 saniye yavaşça nefes almasını söyleyin.',
            '"Mum söndürme": ağzından 6 saniye yavaşça üflemesini isteyin.',
            'Bunu 5 kez tekrarlayın.',
            'Her nefeste daha sakin hissettiğini fark etmesini sağlayın.',
          ],
        ),
        _Activity(
          title: 'Vücut Taraması',
          icon: Icons.self_improvement,
          ageRange: '5–12 yaş',
          duration: '5–10 dk',
          benefit: 'Vücut farkındalığı ve gevşeme becerisi kazandırır. Uyumadan önce zihni ve bedeni sakinleştirir.',
          steps: [
            'Çocuğunuz sırt üstü uzansın ve gözlerini kapatsın.',
            '"Ayak parmaklarını sık ve bırak" diyerek ayaklardan başlayın.',
            'Sırasıyla bacaklar, karın, eller, kollar, omuzlar ve yüz kaslarını sıkıp bırakmasını isteyin.',
            'Her bölgede "şimdi orası sıcacık ve gevşemiş" diye fısıldayın.',
            'Tüm vücut tamamlanınca sessizce yatmasına izin verin.',
          ],
        ),
        _Activity(
          title: 'Hayal Yolculuğu',
          icon: Icons.cloud,
          ageRange: '4–10 yaş',
          duration: '10 dk',
          benefit: 'Hayal gücünü beslerken uykuya geçişi kolaylaştırır. Huzurlu bir uyku ortamı yaratır.',
          steps: [
            'Odayı karanlık yapın, sadece gece lambası kalsın.',
            'Yavaş ve sakin bir sesle anlatmaya başlayın: "Gözlerini kapa, şimdi yumuşak bir bulutun üstündesin..."',
            'Bir orman, plaj veya uzay yolculuğu gibi sakin bir mekan tarif edin.',
            'Detaylar ekleyin: sesler, kokular, sıcaklık hissi.',
            'Hikaye yavaşça sessizliğe karışsın ve çocuğunuzun uykuya dalmasını bekleyin.',
          ],
        ),
      ],
    ),
    _Category(
      title: 'Ekran Molası Alternatifleri',
      icon: Icons.phonelink_off_rounded,
      color: Color(0xFF06B6D4),
      activities: [
        _Activity(
          title: 'Lego Meydan Okuması',
          icon: Icons.extension,
          ageRange: '4–12 yaş',
          duration: '20–30 dk',
          benefit: 'Mekânsal düşünme, planlama ve ince motor becerilerini geliştirir. Ekran yerine üretken bir alternatif sunar.',
          steps: [
            'Bir tema belirleyin: "Bugün bir köprü yapıyoruz!"',
            'Süre koyun (20 dakika) ve malzemeleri çıkarın.',
            'Herkes kendi modelini yapsın veya birlikte çalışsın.',
            'Süre bitince modelleri birbirinize tanıtın.',
            'Her hafta farklı temalar seçin: hayvanat bahçesi, uzay aracı, rüya evi vb.',
          ],
        ),
        _Activity(
          title: 'Karton Kutu Dünyası',
          icon: Icons.inventory_2,
          ageRange: '3–8 yaş',
          duration: '30–60 dk',
          benefit: 'Yaratıcılık, problem çözme ve yeniden kullanım bilinci kazandırır. Basit malzemelerden büyük projeler çıkarmayı öğretir.',
          steps: [
            'Büyük bir karton kutu bulun (kargo kutusu vb.).',
            'Çocuğunuza sorun: "Bu kutu ne olabilir? Araba mı, gemi mi, ev mi?"',
            'Boya, keçeli kalem ve yapıştırıcı ile birlikte süsleyin.',
            'Kapı, pencere, direksiyon gibi detaylar ekleyin.',
            'Tamamlanınca içinde oynasın ve hikayeler uydursun.',
          ],
        ),
        _Activity(
          title: 'Bilim Deneyi: Volkan',
          icon: Icons.science,
          ageRange: '5–12 yaş',
          duration: '20–30 dk',
          benefit: 'Merak ve bilimsel düşünmeyi uyandırır. Neden–sonuç ilişkisini somut olarak deneyimletir.',
          steps: [
            'Malzemeler: karbonat, sirke, bulaşık deterjanı, gıda boyası, plastik şişe.',
            'Şişeyi bir tepsi üzerine koyun ve etrafını hamur veya kartonla volkan şekline getirin.',
            'Şişeye 2 yemek kaşığı karbonat ve birkaç damla deterjan koyun.',
            'Gıda boyası ekleyin (kırmızı veya turuncu).',
            'Sirkeyi dökün ve "lavın" fışkırmasını birlikte izleyin. Kimyasal reaksiyonu basitçe anlatın.',
          ],
        ),
      ],
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final r = Responsive(context);
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: SingleChildScrollView(
        padding: r.pagePadding(horizontal: 20, top: 8, bottom: 120),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Başlık
            Padding(
              padding: EdgeInsets.only(bottom: r.scale(4)),
              child: Text(
                'Aktiviteler',
                style: TextStyle(
                  fontSize: r.scale(24),
                  fontWeight: FontWeight.w800,
                  color: AppTheme.textDark,
                ),
              ),
            ),
            Text(
              'Çocuğunuzla birlikte yapabileceğiniz eğlenceli ve gelişimi destekleyen aktiviteler',
              style: TextStyle(
                fontSize: r.scale(13),
                color: AppTheme.textGray,
                height: 1.4,
              ),
            ),
            SizedBox(height: r.scale(20)),
            ..._categories.map((cat) => _CategorySection(category: cat)),
          ],
        ),
      ),
    );
  }
}

// ─── Data Models ───

class _Activity {
  final String title;
  final IconData icon;
  final String ageRange;
  final String duration;
  final String benefit;
  final List<String> steps;

  const _Activity({
    required this.title,
    required this.icon,
    required this.ageRange,
    required this.duration,
    required this.benefit,
    required this.steps,
  });
}

class _Category {
  final String title;
  final IconData icon;
  final Color color;
  final List<_Activity> activities;

  const _Category({
    required this.title,
    required this.icon,
    required this.color,
    required this.activities,
  });
}

// ─── Category Section ───

class _CategorySection extends StatelessWidget {
  final _Category category;

  const _CategorySection({required this.category});

  @override
  Widget build(BuildContext context) {
    final r = Responsive(context);
    return Padding(
      padding: EdgeInsets.only(bottom: r.scale(20)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Kategori başlığı
          Row(
            children: [
              SizedBox(
                width: r.scale(36),
                height: r.scale(36),
                child: Neumorphic(
                  style: AppTheme.nCircle(),
                  child: Center(
                    child: Icon(category.icon, color: category.color, size: r.scale(18)),
                  ),
                ),
              ),
              SizedBox(width: r.scale(10)),
              Text(
                category.title,
                style: TextStyle(
                  fontSize: r.scale(17),
                  fontWeight: FontWeight.w800,
                  color: AppTheme.textDark,
                ),
              ),
            ],
          ),
          SizedBox(height: r.scale(12)),
          // Aktivite kartları — yatay kaydırmalı
          SizedBox(
            height: r.scale(150),
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              clipBehavior: Clip.none,
              padding: EdgeInsets.symmetric(vertical: r.scale(8)),
              itemCount: category.activities.length,
              separatorBuilder: (_, __) => SizedBox(width: r.scale(12)),
              itemBuilder: (context, index) {
                final act = category.activities[index];
                return _ActivityCard(
                  activity: act,
                  color: category.color,
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => _ActivityDetailPage(activity: act, color: category.color),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Activity Card ───

class _ActivityCard extends StatelessWidget {
  final _Activity activity;
  final Color color;
  final VoidCallback onTap;

  const _ActivityCard({
    required this.activity,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final r = Responsive(context);
    return GestureDetector(
      onTap: onTap,
      child: SizedBox(
        width: r.scale(150),
        child: Neumorphic(
          style: AppTheme.nConvex(radius: r.scale(16)),
          padding: EdgeInsets.all(r.scale(14)),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(activity.icon, color: color, size: r.scale(22)),
                  const Spacer(),
                  Icon(Icons.arrow_forward_ios_rounded, color: AppTheme.textGray.withOpacity(0.4), size: r.scale(12)),
                ],
              ),
              const Spacer(),
              Text(
                activity.title,
                style: TextStyle(
                  fontSize: r.scale(13),
                  fontWeight: FontWeight.w700,
                  color: AppTheme.textDark,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              SizedBox(height: r.scale(4)),
              Row(
                children: [
                  Icon(Icons.schedule_rounded, size: r.scale(11), color: AppTheme.textGray),
                  SizedBox(width: r.scale(4)),
                  Text(
                    activity.duration,
                    style: TextStyle(fontSize: r.scale(10), color: AppTheme.textGray),
                  ),
                  SizedBox(width: r.scale(8)),
                  Icon(Icons.child_care_rounded, size: r.scale(11), color: AppTheme.textGray),
                  SizedBox(width: r.scale(4)),
                  Flexible(
                    child: Text(
                      activity.ageRange,
                      style: TextStyle(fontSize: r.scale(10), color: AppTheme.textGray),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Activity Detail Page ───

class _ActivityDetailPage extends StatelessWidget {
  final _Activity activity;
  final Color color;

  const _ActivityDetailPage({required this.activity, required this.color});

  @override
  Widget build(BuildContext context) {
    final r = Responsive(context);
    return Scaffold(
      backgroundColor: AppTheme.nBase,
      body: SafeArea(
        child: Column(
          children: [
            // Üst bar
            Padding(
              padding: EdgeInsets.fromLTRB(r.scale(16), r.scale(8), r.scale(16), r.scale(4)),
              child: Row(
                children: [
                  NeumorphicButton(
                    style: AppTheme.nFlat(radius: r.scale(14)),
                    padding: EdgeInsets.all(r.scale(10)),
                    onPressed: () => Navigator.pop(context),
                    child: Icon(Icons.arrow_back_rounded, size: r.scale(20), color: AppTheme.textDark),
                  ),
                  SizedBox(width: r.scale(12)),
                  Expanded(
                    child: Text(
                      activity.title,
                      style: TextStyle(
                        fontSize: r.scale(18),
                        fontWeight: FontWeight.w800,
                        color: AppTheme.textDark,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: r.pagePadding(horizontal: 20, top: 12, bottom: 32),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Bilgi kartı
                    Neumorphic(
                      style: AppTheme.nConvex(radius: r.scale(20)),
                      padding: EdgeInsets.all(r.scale(20)),
                      child: Column(
                        children: [
                          SizedBox(
                            width: r.scale(60),
                            height: r.scale(60),
                            child: Neumorphic(
                              style: AppTheme.nCircle(depth: 7),
                              child: Center(
                                child: Icon(activity.icon, color: color, size: r.scale(28)),
                              ),
                            ),
                          ),
                          SizedBox(height: r.scale(16)),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              _InfoChip(icon: Icons.schedule_rounded, label: activity.duration),
                              SizedBox(width: r.scale(16)),
                              _InfoChip(icon: Icons.child_care_rounded, label: activity.ageRange),
                            ],
                          ),
                        ],
                      ),
                    ),
                    SizedBox(height: r.scale(16)),

                    // Fayda kartı
                    Neumorphic(
                      style: AppTheme.nConvex(radius: r.scale(20)),
                      padding: EdgeInsets.all(r.scale(18)),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(Icons.auto_awesome, color: color, size: r.scale(20)),
                              SizedBox(width: r.scale(8)),
                              Text(
                                'Ne İşe Yarar?',
                                style: TextStyle(
                                  fontSize: r.scale(16),
                                  fontWeight: FontWeight.w700,
                                  color: AppTheme.textDark,
                                ),
                              ),
                            ],
                          ),
                          SizedBox(height: r.scale(12)),
                          Text(
                            activity.benefit,
                            style: TextStyle(
                              fontSize: r.scale(14),
                              color: AppTheme.textDark,
                              height: 1.6,
                            ),
                          ),
                        ],
                      ),
                    ),
                    SizedBox(height: r.scale(16)),

                    // Adımlar kartı
                    Neumorphic(
                      style: AppTheme.nConvex(radius: r.scale(20)),
                      padding: EdgeInsets.all(r.scale(18)),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(Icons.format_list_numbered_rounded, color: color, size: r.scale(20)),
                              SizedBox(width: r.scale(8)),
                              Text(
                                'Nasıl Yapılır?',
                                style: TextStyle(
                                  fontSize: r.scale(16),
                                  fontWeight: FontWeight.w700,
                                  color: AppTheme.textDark,
                                ),
                              ),
                            ],
                          ),
                          SizedBox(height: r.scale(16)),
                          ...List.generate(activity.steps.length, (i) {
                            return Padding(
                              padding: EdgeInsets.only(bottom: r.scale(14)),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  SizedBox(
                                    width: r.scale(28),
                                    height: r.scale(28),
                                    child: Neumorphic(
                                      style: AppTheme.nCircle(depth: 4),
                                      child: Center(
                                        child: Text(
                                          '${i + 1}',
                                          style: TextStyle(
                                            fontSize: r.scale(12),
                                            fontWeight: FontWeight.w800,
                                            color: color,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                  SizedBox(width: r.scale(12)),
                                  Expanded(
                                    child: Padding(
                                      padding: EdgeInsets.only(top: r.scale(4)),
                                      child: Text(
                                        activity.steps[i],
                                        style: TextStyle(
                                          fontSize: r.scale(14),
                                          color: AppTheme.textDark,
                                          height: 1.5,
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
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
          ],
        ),
      ),
    );
  }
}

class _InfoChip extends StatelessWidget {
  final IconData icon;
  final String label;

  const _InfoChip({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    final r = Responsive(context);
    return Neumorphic(
      style: AppTheme.nConcave(radius: 999),
      padding: EdgeInsets.symmetric(horizontal: r.scale(12), vertical: r.scale(6)),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: r.scale(14), color: AppTheme.textGray),
          SizedBox(width: r.scale(6)),
          Text(
            label,
            style: TextStyle(fontSize: r.scale(12), fontWeight: FontWeight.w600, color: AppTheme.textDark),
          ),
        ],
      ),
    );
  }
}
