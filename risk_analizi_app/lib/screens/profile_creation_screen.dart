import 'package:flutter/material.dart';
import 'package:flutter_neumorphic_plus/flutter_neumorphic.dart';
import '../core/responsive.dart';
import '../core/theme.dart';
import '../models/child_profile.dart';
import '../services/storage_service.dart';
import 'app_navigation_shell.dart';

class ProfileCreationScreen extends StatefulWidget {
  const ProfileCreationScreen({super.key});

  @override
  State<ProfileCreationScreen> createState() => _ProfileCreationScreenState();
}

class _ProfileCreationScreenState extends State<ProfileCreationScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();

  int _cinsiyet = 0;
  double _yas = 8;
  double _boy = 130;
  double _kilo = 30;

  void _saveProfile() async {
    if (_formKey.currentState!.validate()) {
      final profile = ChildProfile(
        name: _nameController.text.trim(),
        gender: _cinsiyet,
        age: _yas,
        heightCm: _boy,
        weightKg: _kilo,
      );

      await StorageService.saveProfile(profile);

      if (!mounted) return;
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => AppNavigationShell(profile: profile)),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final r = Responsive(context);
    return Scaffold(
      backgroundColor: AppTheme.backgroundOffWhite,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: r.pagePadding(horizontal: 24, top: 12, bottom: 28),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header card
                Container(
                  width: double.infinity,
                  padding: EdgeInsets.all(r.scale(22)),
                  decoration: BoxDecoration(
                    gradient: AppTheme.primaryGradient,
                    borderRadius: BorderRadius.circular(r.scale(24)),
                    boxShadow: [
                      BoxShadow(
                        color: AppTheme.primaryBlue.withOpacity(0.3),
                        blurRadius: 20,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: EdgeInsets.all(r.scale(10)),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(r.scale(12)),
                            ),
                            child: Icon(Icons.child_care_rounded, color: Colors.white, size: r.scale(24)),
                          ),
                          SizedBox(width: r.scale(12)),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Çocuk Profili',
                                style: TextStyle(color: Colors.white, fontSize: r.scale(22), fontWeight: FontWeight.w700),
                              ),
                              Text(
                                'Kişiselleştirilmiş risk analizi',
                                style: TextStyle(color: Colors.white.withOpacity(0.7), fontSize: r.scale(14)),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                SizedBox(height: r.scale(28)),

                // Avatar
                Center(
                  child: Container(
                    width: r.scale(90),
                    height: r.scale(90),
                    decoration: BoxDecoration(
                      color: AppTheme.primaryBlue.withOpacity(0.08),
                      borderRadius: BorderRadius.circular(r.scale(24)),
                    ),
                    child: Icon(Icons.child_care, size: r.scale(44), color: AppTheme.primaryBlue),
                  ),
                ),
                SizedBox(height: r.scale(28)),

                // Name
                TextFormField(
                  controller: _nameController,
                  decoration: InputDecoration(
                    labelText: 'Çocuğun Adı',
                    prefixIcon: const Icon(Icons.person_outline),
                  ),
                  validator: (val) => val == null || val.isEmpty ? 'İsim gerekli' : null,
                ),
                SizedBox(height: r.scale(24)),

                // Gender
                Text('Cinsiyet', style: TextStyle(fontWeight: FontWeight.w600, color: AppTheme.textDark, fontSize: r.scale(15))),
                SizedBox(height: r.scale(10)),
                Row(
                  children: [
                    Expanded(
                      child: GestureDetector(
                        onTap: () => setState(() => _cinsiyet = 0),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          padding: EdgeInsets.symmetric(vertical: r.scale(14)),
                          decoration: BoxDecoration(
                            color: _cinsiyet == 0 ? AppTheme.primaryBlue : Colors.white,
                            borderRadius: BorderRadius.circular(r.scale(14)),
                            border: Border.all(
                              color: _cinsiyet == 0 ? AppTheme.primaryBlue : const Color(0xFFE2E8F0),
                            ),
                          ),
                          child: Center(
                            child: Text(
                              'Erkek',
                              style: TextStyle(
                                color: _cinsiyet == 0 ? Colors.white : AppTheme.textDark,
                                fontWeight: FontWeight.w600,
                                fontSize: r.scale(15),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                    SizedBox(width: r.scale(12)),
                    Expanded(
                      child: GestureDetector(
                        onTap: () => setState(() => _cinsiyet = 1),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          padding: EdgeInsets.symmetric(vertical: r.scale(14)),
                          decoration: BoxDecoration(
                            color: _cinsiyet == 1 ? AppTheme.primaryBlue : Colors.white,
                            borderRadius: BorderRadius.circular(r.scale(14)),
                            border: Border.all(
                              color: _cinsiyet == 1 ? AppTheme.primaryBlue : const Color(0xFFE2E8F0),
                            ),
                          ),
                          child: Center(
                            child: Text(
                              'Kız',
                              style: TextStyle(
                                color: _cinsiyet == 1 ? Colors.white : AppTheme.textDark,
                                fontWeight: FontWeight.w600,
                                fontSize: r.scale(15),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                SizedBox(height: r.scale(24)),

                // Sliders
                _buildSlider(r, label: 'Yaş', value: _yas, suffix: '', min: 6, max: 18, divisions: 12, onChanged: (v) => setState(() => _yas = v)),
                _buildSlider(r, label: 'Boy', value: _boy, suffix: ' cm', min: 100, max: 200, divisions: 100, onChanged: (v) => setState(() => _boy = v)),
                _buildSlider(r, label: 'Kilo', value: _kilo, suffix: ' kg', min: 15, max: 120, divisions: 105, onChanged: (v) => setState(() => _kilo = v)),

                SizedBox(height: r.scale(36)),

                // Save button
                SizedBox(
                  width: double.infinity,
                  height: r.scale(56),
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: AppTheme.primaryGradient,
                      borderRadius: BorderRadius.circular(r.scale(16)),
                      boxShadow: [
                        BoxShadow(
                          color: AppTheme.primaryBlue.withOpacity(0.3),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: ElevatedButton(
                      onPressed: _saveProfile,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.transparent,
                        shadowColor: Colors.transparent,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(r.scale(16)),
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.check_circle_outline_rounded, color: Colors.white, size: r.scale(20)),
                          SizedBox(width: r.scale(8)),
                          Text(
                            'Profili Kaydet ve Başla',
                            style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: r.scale(16)),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSlider(
    Responsive r, {
    required String label,
    required double value,
    required String suffix,
    required double min,
    required double max,
    required int divisions,
    required ValueChanged<double> onChanged,
  }) {
    return Padding(
      padding: EdgeInsets.only(bottom: r.scale(16)),
      child: Neumorphic(
        style: AppTheme.nConvex(radius: r.scale(16)),
        padding: EdgeInsets.fromLTRB(r.scale(18), r.scale(14), r.scale(18), r.scale(8)),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(label, style: TextStyle(fontWeight: FontWeight.w600, color: AppTheme.textDark, fontSize: r.scale(15))),
                Container(
                  padding: EdgeInsets.symmetric(horizontal: r.scale(12), vertical: r.scale(5)),
                  decoration: BoxDecoration(
                    color: AppTheme.primaryBlue.withOpacity(0.08),
                    borderRadius: BorderRadius.circular(r.scale(8)),
                  ),
                  child: Text(
                    '${value.toInt()}$suffix',
                    style: TextStyle(color: AppTheme.primaryBlue, fontWeight: FontWeight.w700, fontSize: r.scale(14)),
                  ),
                ),
              ],
            ),
            SizedBox(height: r.scale(4)),
            SliderTheme(
              data: SliderTheme.of(context).copyWith(
                trackHeight: r.scale(5),
                thumbShape: RoundSliderThumbShape(enabledThumbRadius: r.scale(9)),
                overlayShape: RoundSliderOverlayShape(overlayRadius: r.scale(16)),
              ),
              child: Slider(
                value: value,
                min: min,
                max: max,
                divisions: divisions,
                onChanged: onChanged,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
