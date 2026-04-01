import 'package:flutter/material.dart';
import '../core/theme.dart';
import '../models/child_profile.dart';
import '../services/storage_service.dart';
import 'dashboard_screen.dart';

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
        MaterialPageRoute(builder: (_) => DashboardScreen(profile: profile)),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundLight,
      appBar: AppBar(
        title: const Text('Profil Oluştur'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
               Container(
                 width: double.infinity,
                 padding: const EdgeInsets.all(20),
                 decoration: BoxDecoration(
                   gradient: const LinearGradient(
                     colors: [AppTheme.primaryBlue, AppTheme.secondaryBlue],
                     begin: Alignment.topLeft,
                     end: Alignment.bottomRight,
                   ),
                   borderRadius: BorderRadius.circular(24),
                 ),
                 child: const Column(
                   crossAxisAlignment: CrossAxisAlignment.start,
                   children: [
                     Text(
                       'Çocuk Profili',
                       style: TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.w700),
                     ),
                     SizedBox(height: 8),
                     Text(
                       'Temel bilgileri girerek kişiselleştirilmiş risk analizi başlatın.',
                       style: TextStyle(color: Colors.white70, fontSize: 14),
                     ),
                   ],
                 ),
               ),
               const SizedBox(height: 24),
               Center(
                 child: CircleAvatar(
                   radius: 50,
                   backgroundColor: AppTheme.primaryBlue.withOpacity(0.1),
                   child: const Icon(Icons.child_care, size: 50, color: AppTheme.primaryBlue),
                 ),
               ),
               const SizedBox(height: 32),
               
               // İsim
               TextFormField(
                 controller: _nameController,
                 decoration: const InputDecoration(
                   labelText: 'Çocuğun Adı',
                   prefixIcon: Icon(Icons.person),
                 ),
                 validator: (val) => val == null || val.isEmpty ? 'İsim gerekli' : null,
               ),
               const SizedBox(height: 24),

               // Cinsiyet
               const Text('Cinsiyet', style: TextStyle(fontWeight: FontWeight.w600, color: AppTheme.textDark)),
               const SizedBox(height: 8),
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
               const SizedBox(height: 24),

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
                const SizedBox(height: 16),

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
                const SizedBox(height: 16),

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
                const SizedBox(height: 48),

                SizedBox(
                  width: double.infinity,
                  height: 60,
                  child: ElevatedButton(
                    onPressed: _saveProfile,
                    child: const Text('Profili Kaydet ve Başla'),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
