import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_neumorphic_plus/flutter_neumorphic.dart';
import 'core/responsive.dart';
import 'core/theme.dart';
import 'screens/app_navigation_shell.dart';
import 'screens/profile_creation_screen.dart';
import 'services/storage_service.dart';

void main() {
  runApp(const RiskAnaliziApp());
}

class RiskAnaliziApp extends StatelessWidget {
  const RiskAnaliziApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Zeka Katmanlari',
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
      builder: (context, child) {
        return NeumorphicTheme(
          theme: AppTheme.neumorphicTheme,
          child: child!,
        );
      },
      home: const AppInitializer(),
    );
  }
}

class AppInitializer extends StatefulWidget {
  const AppInitializer({super.key});
  @override
  State<AppInitializer> createState() => _AppInitializerState();
}

class _AppInitializerState extends State<AppInitializer>
    with SingleTickerProviderStateMixin {
  late AnimationController _animCtrl;
  late Animation<double> _fadeAnim;
  late Animation<double> _scaleAnim;

  @override
  void initState() {
    super.initState();
    _animCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );
    _fadeAnim = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _animCtrl, curve: const Interval(0, 0.6, curve: Curves.easeOut)),
    );
    _scaleAnim = Tween<double>(begin: 0.8, end: 1).animate(
      CurvedAnimation(parent: _animCtrl, curve: const Interval(0, 0.6, curve: Curves.easeOutBack)),
    );
    _animCtrl.forward();
    _checkProfile();
  }

  @override
  void dispose() {
    _animCtrl.dispose();
    super.dispose();
  }

  Future<void> _checkProfile() async {
    final profile = await StorageService.getProfile();
    await Future.delayed(const Duration(milliseconds: 1400));

    if (!mounted) return;

    if (profile != null) {
      Navigator.pushReplacement(
        context,
        PageRouteBuilder(
          pageBuilder: (_, __, ___) => AppNavigationShell(profile: profile),
          transitionsBuilder: (_, a, __, child) =>
              FadeTransition(opacity: a, child: child),
          transitionDuration: const Duration(milliseconds: 500),
        ),
      );
    } else {
      Navigator.pushReplacement(
        context,
        PageRouteBuilder(
          pageBuilder: (_, __, ___) => const ProfileCreationScreen(),
          transitionsBuilder: (_, a, __, child) =>
              FadeTransition(opacity: a, child: child),
          transitionDuration: const Duration(milliseconds: 500),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final r = Responsive(context);
    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: AppTheme.primaryGradient,
        ),
        child: AnimatedBuilder(
          animation: _animCtrl,
          builder: (context, child) {
            return Opacity(
              opacity: _fadeAnim.value,
              child: Transform.scale(
                scale: _scaleAnim.value,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      width: r.scale(100),
                      height: r.scale(100),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(r.scale(28)),
                      ),
                      child: Icon(
                        Icons.health_and_safety_rounded,
                        size: r.scale(52),
                        color: Colors.white,
                      ),
                    ),
                    SizedBox(height: r.scale(28)),
                    Text(
                      'Zeka Katmanlari',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w800,
                        fontSize: r.scale(30),
                        letterSpacing: -0.5,
                      ),
                    ),
                    SizedBox(height: r.scale(8)),
                    Text(
                      'Cocuk Gelisim Analizi',
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.7),
                        fontSize: r.scale(15),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    SizedBox(height: r.scale(48)),
                    SizedBox(
                      width: r.scale(160),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(r.scale(4)),
                        child: LinearProgressIndicator(
                          backgroundColor: Colors.white.withOpacity(0.2),
                          valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
                          minHeight: r.scale(3),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
