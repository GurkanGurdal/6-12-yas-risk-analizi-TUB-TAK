import 'package:flutter/material.dart';

import '../core/responsive.dart';
import '../core/theme.dart';
import '../models/child_profile.dart';
import '../services/storage_service.dart';

class ProfilesScreen extends StatefulWidget {
  final ChildProfile initialProfile;
  final ValueChanged<ChildProfile> onActiveProfileChanged;

  const ProfilesScreen({
    super.key,
    required this.initialProfile,
    required this.onActiveProfileChanged,
  });

  @override
  State<ProfilesScreen> createState() => _ProfilesScreenState();
}

class _ProfilesScreenState extends State<ProfilesScreen> {
  late ChildProfile _activeProfile;
  List<ChildProfile> _profiles = [];

  @override
  void initState() {
    super.initState();
    _activeProfile = widget.initialProfile;
    _refreshProfiles();
  }

  Future<void> _refreshProfiles() async {
    final latestActive = await StorageService.getProfile();
    final profiles = await StorageService.getProfiles();
    if (!mounted) return;

    setState(() {
      _profiles = profiles;
      if (latestActive != null) {
        _activeProfile = latestActive;
      }
    });
  }

  bool _isActive(ChildProfile p) {
    return p.name == _activeProfile.name &&
        p.gender == _activeProfile.gender &&
        p.age == _activeProfile.age &&
        p.heightCm == _activeProfile.heightCm &&
        p.weightKg == _activeProfile.weightKg;
  }

  Future<void> _selectProfile(ChildProfile profile) async {
    await StorageService.setActiveProfile(profile);
    if (!mounted) return;

    setState(() => _activeProfile = profile);
    widget.onActiveProfileChanged(profile);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('${profile.name} aktif profil olarak secildi.')),
    );
  }

  Future<void> _deleteProfile(int index) async {
    if (_profiles.length <= 1) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('En az bir profil kalmali.')),
      );
      return;
    }

    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Profili Sil'),
        content: const Text('Bu profili silmek istediginize emin misiniz?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Iptal')),
          ElevatedButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Sil')),
        ],
      ),
    );

    if (confirm != true) return;

    await StorageService.deleteProfileAt(index);
    await _refreshProfiles();

    if (_profiles.isNotEmpty) {
      widget.onActiveProfileChanged(_activeProfile);
    }
  }

  Future<void> _addProfile() async {
    final formKey = GlobalKey<FormState>();
    final nameController = TextEditingController();
    int gender = 0;
    double age = 8;
    double height = 130;
    double weight = 30;

    final created = await showDialog<ChildProfile>(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Text('Yeni Profil Ekle'),
              content: SingleChildScrollView(
                child: Form(
                  key: formKey,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      TextFormField(
                        controller: nameController,
                        decoration: const InputDecoration(labelText: 'Ad Soyad'),
                        validator: (v) => v == null || v.trim().isEmpty ? 'Ad gerekli' : null,
                      ),
                      const SizedBox(height: 12),
                      const Text('Cinsiyet', style: TextStyle(fontWeight: FontWeight.w600)),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Expanded(
                            child: ChoiceChip(
                              label: const Text('Erkek'),
                              selected: gender == 0,
                              onSelected: (_) => setDialogState(() => gender = 0),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: ChoiceChip(
                              label: const Text('Kiz'),
                              selected: gender == 1,
                              onSelected: (_) => setDialogState(() => gender = 1),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Text('Yas: ${age.toInt()}'),
                      Slider(
                        value: age,
                        min: 6,
                        max: 18,
                        divisions: 12,
                        onChanged: (v) => setDialogState(() => age = v),
                      ),
                      Text('Boy: ${height.toInt()} cm'),
                      Slider(
                        value: height,
                        min: 100,
                        max: 200,
                        onChanged: (v) => setDialogState(() => height = v),
                      ),
                      Text('Kilo: ${weight.toInt()} kg'),
                      Slider(
                        value: weight,
                        min: 15,
                        max: 120,
                        onChanged: (v) => setDialogState(() => weight = v),
                      ),
                    ],
                  ),
                ),
              ),
              actions: [
                TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Iptal')),
                ElevatedButton(
                  onPressed: () {
                    if (!formKey.currentState!.validate()) return;
                    Navigator.pop(
                      ctx,
                      ChildProfile(
                        name: nameController.text.trim(),
                        gender: gender,
                        age: age,
                        heightCm: height,
                        weightKg: weight,
                      ),
                    );
                  },
                  child: const Text('Ekle'),
                ),
              ],
            );
          },
        );
      },
    );

    if (created == null) return;

    await StorageService.addProfile(created);
    await StorageService.setActiveProfile(created);
    await _refreshProfiles();
    widget.onActiveProfileChanged(created);
  }

  String _genderText(ChildProfile p) => p.gender == 0 ? 'Erkek' : 'Kiz';

  @override
  Widget build(BuildContext context) {
    final r = Responsive(context);
    return Scaffold(
      backgroundColor: Colors.transparent,
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _addProfile,
        icon: const Icon(Icons.person_add_alt_1),
        label: const Text('Profil Ekle'),
      ),
      body: RefreshIndicator(
        onRefresh: _refreshProfiles,
        child: ListView(
          padding: r.pagePadding(horizontal: 20, top: 8, bottom: 120),
          children: [
            Container(
              padding: EdgeInsets.all(r.scale(20)),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [AppTheme.secondaryBlue, AppTheme.primaryBlue],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(r.scale(24)),
              ),
              child: Text(
                'Toplam ${_profiles.length} profil • Aktif: ${_activeProfile.name}',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: r.scale(16),
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            SizedBox(height: r.scale(14)),
            ..._profiles.asMap().entries.map((entry) {
              final index = entry.key;
              final p = entry.value;
              final active = _isActive(p);

              return Card(
                margin: EdgeInsets.only(bottom: r.scale(10)),
                color: AppTheme.secondaryBlue,
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: active ? AppTheme.primaryBlue : AppTheme.primaryBlue.withOpacity(0.12),
                    child: Text(
                      p.initial,
                      style: TextStyle(
                        color: active ? Colors.white : AppTheme.primaryBlue,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  title: Text(p.name, style: const TextStyle(fontWeight: FontWeight.w700)),
                  textColor: AppTheme.textOnDark,
                  subtitle: Text(
                    '${p.age.toInt()} yas • ${_genderText(p)} • ${p.heightCm.toInt()}cm / ${p.weightKg.toInt()}kg',
                    style: TextStyle(color: AppTheme.mutedOnDark, fontSize: r.scale(13)),
                  ),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (active)
                        Container(
                          padding: EdgeInsets.symmetric(horizontal: r.scale(8), vertical: r.scale(4)),
                          margin: EdgeInsets.only(right: r.scale(4)),
                          decoration: BoxDecoration(
                            color: AppTheme.riskGreen.withOpacity(0.14),
                            borderRadius: BorderRadius.circular(999),
                          ),
                          child: Text(
                            'Aktif',
                            style: TextStyle(
                              color: AppTheme.riskGreen,
                              fontSize: r.scale(12),
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      IconButton(
                        tooltip: 'Profili sec',
                        icon: const Icon(Icons.check_circle_outline),
                        onPressed: () => _selectProfile(p),
                      ),
                      IconButton(
                        tooltip: 'Profili sil',
                        icon: const Icon(Icons.delete_outline, color: AppTheme.riskRed),
                        onPressed: () => _deleteProfile(index),
                      ),
                    ],
                  ),
                ),
              );
            }),
          ],
        ),
      ),
    );
  }
}
