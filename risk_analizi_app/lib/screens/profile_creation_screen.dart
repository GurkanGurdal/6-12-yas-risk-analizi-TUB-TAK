import 'package:flutter/material.dart';
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
  
  int _cinsiyet = 0; // 0: Erkek, 1: Kız
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
      backgroundColor: Colors.transparent,
      body: SafeArea(
        child: SingleChildScrollView(
        padding: r.pagePadding(horizontal: 24, top: 12, bottom: 28),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
               Container(
                 width: double.infinity,
                 padding: EdgeInsets.all(r.scale(20)),
                 decoration: BoxDecoration(
                   gradient: const LinearGradient(
                     colors: [AppTheme.primaryBlue, AppTheme.secondaryBlue],
                     begin: Alignment.topLeft,
                     end: Alignment.bottomRight,
                   ),
                   borderRadius: BorderRadius.circular(r.scale(24)),
                 ),
                 child: Column(
                   crossAxisAlignment: CrossAxisAlignment.start,
                   children: [
                     Text(
                       'Çocuk Profili',
                       style: TextStyle(color: Colors.white, fontSize: r.scale(22), fontWeight: FontWeight.w700),
                     ),
                     SizedBox(height: r.scale(8)),
                     Text(
                       'Temel bilgileri girerek kişiselleştirilmiş risk analizi başlatın.',
                       style: TextStyle(color: Colors.white70, fontSize: r.scale(14)),
                     ),
                   ],
                 ),
               ),
               SizedBox(height: r.scale(24)),
               Center(
                 child: CircleAvatar(
                   radius: r.scale(50),
                   backgroundColor: AppTheme.primaryBlue.withOpacity(0.1),
                   child: Icon(Icons.child_care, size: r.scale(50), color: AppTheme.primaryBlue),
                 ),
               ),
               SizedBox(height: r.scale(32)),
               
               // İsim
               TextFormField(
                 controller: _nameController,
                 decoration: const InputDecoration(
                   labelText: 'Çocuğun Adı',
                   prefixIcon: Icon(Icons.person),
                 ),
                 validator: (val) => val == null || val.isEmpty ? 'İsim gerekli' : null,
               ),
               SizedBox(height: r.scale(24)),

               // Cinsiyet
               const Text('Cinsiyet', style: TextStyle(fontWeight: FontWeight.w600, color: AppTheme.textDark)),
               SizedBox(height: r.scale(8)),
               Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    ChoiceChip(
                      label: const Padding(
                        padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        child: Text('Erkek'),
                      ),
                      selected: _cinsiyet == 0,
                      selectedColor: AppTheme.primaryBlue.withOpacity(0.2),
                      onSelected: (val) => setState(() => _cinsiyet = 0),
                    ),
                    ChoiceChip(
                      label: const Padding(
                        padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        child: Text('Kız'),
                      ),
                      selected: _cinsiyet == 1,
                      selectedColor: AppTheme.primaryBlue.withOpacity(0.2),
                      onSelected: (val) => setState(() => _cinsiyet = 1),
                    ),
                  ],
               ),
               SizedBox(height: r.scale(24)),

               // Yaş
               Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Yaş', style: TextStyle(fontWeight: FontWeight.w600)),
                    Text('${_yas.toInt()} Yaş', style: const TextStyle(color: AppTheme.primaryBlue)),
                  ],
                ),
                Slider(
                  value: _yas,
                  min: 6, max: 18, divisions: 12,
                  activeColor: AppTheme.primaryBlue,
                  onChanged: (val) => setState(() => _yas = val),
                ),
                SizedBox(height: r.scale(16)),

                // Boy
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Boy', style: TextStyle(fontWeight: FontWeight.w600)),
                    Text('${_boy.toInt()} cm', style: const TextStyle(color: AppTheme.primaryBlue)),
                  ],
                ),
                Slider(
                  value: _boy,
                  min: 100, max: 200,
                  activeColor: AppTheme.secondaryBlue,
                  onChanged: (val) => setState(() => _boy = val),
                ),
                SizedBox(height: r.scale(16)),

                // Kilo
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Kilo', style: TextStyle(fontWeight: FontWeight.w600)),
                    Text('${_kilo.toInt()} kg', style: const TextStyle(color: AppTheme.primaryBlue)),
                  ],
                ),
                Slider(
                  value: _kilo,
                  min: 15, max: 120,
                  activeColor: AppTheme.secondaryBlue,
                  onChanged: (val) => setState(() => _kilo = val),
                ),
                SizedBox(height: r.scale(48)),

                SizedBox(
                  width: double.infinity,
                  height: r.scale(60),
                  child: ElevatedButton(
                    onPressed: _saveProfile,
                    child: const Text('Profili Kaydet ve Başla'),
                  ),
                ),
            ],
          ),
        ),
      ),
      ),
    );
  }
}
