import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'core/theme.dart';
import 'screens/profile_creation_screen.dart';
import 'screens/dashboard_screen.dart';
import 'services/storage_service.dart';

void main() {
  runApp(const RiskAnaliziApp());
}

class RiskAnaliziApp extends StatelessWidget {
  const RiskAnaliziApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Zeka Katmanları',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [
        Locale('tr', 'TR'),
      ],
      home: const AppInitializer(),
    );
  }
}

class AppInitializer extends StatefulWidget {
  const AppInitializer({super.key});
  @override
  State<AppInitializer> createState() => _AppInitializerState();
}

class _AppInitializerState extends State<AppInitializer> {
  @override
  void initState() {
    super.initState();
    _checkProfile();
  }

  Future<void> _checkProfile() async {
    // Hafızadan profili oku
    final profile = await StorageService.getProfile();
    // 1 sn splash efekti için minik bir bekleme (Opsiyonel)
    await Future.delayed(const Duration(milliseconds: 500));
    
    if (!mounted) return;
    
    // Eğer profil varsa Ana Ekrana (Dashboard), yoksa Kayıt Ekranına (ProfileCreationScreen) geç
    if (profile != null) {
      Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => DashboardScreen(profile: profile)));
    } else {
      Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const ProfileCreationScreen()));
    }
  }

  @override
  Widget build(BuildContext context) {
    // Splash ekranı gibi görünecek basit yükleme durumu
    return Scaffold(
      backgroundColor: AppTheme.primaryBlue,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.health_and_safety, size: 80, color: Colors.white),
            const SizedBox(height: 24),
            Text(
              'Zeka Katmanları',
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 40),
            const CircularProgressIndicator(color: Colors.white),
          ],
        ),
      ),
    );
  }
}
