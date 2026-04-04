import 'package:flutter/material.dart';
import 'package:flutter_neumorphic_plus/flutter_neumorphic.dart';

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
      SnackBar(content: Text('${profile.name} aktif profil olarak se\u00e7ildi.')),
    );
  }

  Future<void> _deleteProfile(int index) async {
    if (_profiles.length <= 1) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('En az bir profil kalmal\u0131.')),
      );
      return;
    }

    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppTheme.nBase,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: const Text('Profili Sil'),
        content: const Text('Bu profili silmek istedi\u011finize emin misiniz?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text('\u0130ptal', style: TextStyle(color: AppTheme.textGray)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.riskRed),
            child: const Text('Sil', style: TextStyle(color: Colors.white)),
          ),
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

  Future<void> _editProfile(int index, ChildProfile existing) async {
    final formKey = GlobalKey<FormState>();
    final nameController = TextEditingController(text: existing.name);
    int gender = existing.gender;
    double age = existing.age;
    double height = existing.heightCm;
    double weight = existing.weightKg;

    final updated = await showDialog<ChildProfile>(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              backgroundColor: AppTheme.nBase,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
              title: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppTheme.primaryBlue.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.edit_rounded, color: AppTheme.primaryBlue, size: 20),
                  ),
                  const SizedBox(width: 10),
                  const Text('Profili D\u00fczenle'),
                ],
              ),
              content: SingleChildScrollView(
                child: Form(
                  key: formKey,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      TextFormField(
                        controller: nameController,
                        decoration: const InputDecoration(
                          labelText: 'Ad Soyad',
                          prefixIcon: Icon(Icons.person_outline),
                        ),
                        validator: (v) => v == null || v.trim().isEmpty ? 'Ad gerekli' : null,
                      ),
                      const SizedBox(height: 16),
                      const Text('Cinsiyet', style: TextStyle(fontWeight: FontWeight.w600, color: AppTheme.textDark)),
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
                              label: const Text('K\u0131z'),
                              selected: gender == 1,
                              onSelected: (_) => setDialogState(() => gender = 1),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      _DialogSlider(
                        label: 'Ya\u015f',
                        value: age,
                        suffix: '',
                        min: 6,
                        max: 18,
                        divisions: 12,
                        onChanged: (v) => setDialogState(() => age = v),
                      ),
                      _DialogSlider(
                        label: 'Boy',
                        value: height,
                        suffix: ' cm',
                        min: 100,
                        max: 200,
                        divisions: 100,
                        onChanged: (v) => setDialogState(() => height = v),
                      ),
                      _DialogSlider(
                        label: 'Kilo',
                        value: weight,
                        suffix: ' kg',
                        min: 15,
                        max: 120,
                        divisions: 105,
                        onChanged: (v) => setDialogState(() => weight = v),
                      ),
                    ],
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: Text('\u0130ptal', style: TextStyle(color: AppTheme.textGray)),
                ),
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
                  child: const Text('Kaydet'),
                ),
              ],
            );
          },
        );
      },
    );

    if (updated == null) return;

    final wasActive = _isActive(existing);
    await StorageService.updateProfileAt(index, updated);
    if (wasActive) {
      await StorageService.setActiveProfile(updated);
    }
    await _refreshProfiles();
    if (wasActive) {
      widget.onActiveProfileChanged(updated);
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
              backgroundColor: AppTheme.nBase,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
              title: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppTheme.primaryBlue.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.person_add_rounded, color: AppTheme.primaryBlue, size: 20),
                  ),
                  const SizedBox(width: 10),
                  const Text('Yeni Profil Ekle'),
                ],
              ),
              content: SingleChildScrollView(
                child: Form(
                  key: formKey,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      TextFormField(
                        controller: nameController,
                        decoration: const InputDecoration(
                          labelText: 'Ad Soyad',
                          prefixIcon: Icon(Icons.person_outline),
                        ),
                        validator: (v) => v == null || v.trim().isEmpty ? 'Ad gerekli' : null,
                      ),
                      const SizedBox(height: 16),
                      const Text('Cinsiyet', style: TextStyle(fontWeight: FontWeight.w600, color: AppTheme.textDark)),
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
                              label: const Text('K\u0131z'),
                              selected: gender == 1,
                              onSelected: (_) => setDialogState(() => gender = 1),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      _DialogSlider(
                        label: 'Ya\u015f',
                        value: age,
                        suffix: '',
                        min: 6,
                        max: 18,
                        divisions: 12,
                        onChanged: (v) => setDialogState(() => age = v),
                      ),
                      _DialogSlider(
                        label: 'Boy',
                        value: height,
                        suffix: ' cm',
                        min: 100,
                        max: 200,
                        divisions: 100,
                        onChanged: (v) => setDialogState(() => height = v),
                      ),
                      _DialogSlider(
                        label: 'Kilo',
                        value: weight,
                        suffix: ' kg',
                        min: 15,
                        max: 120,
                        divisions: 105,
                        onChanged: (v) => setDialogState(() => weight = v),
                      ),
                    ],
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: Text('\u0130ptal', style: TextStyle(color: AppTheme.textGray)),
                ),
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

  String _genderText(ChildProfile p) => p.gender == 0 ? 'Erkek' : 'K\u0131z';

  @override
  Widget build(BuildContext context) {
    final r = Responsive(context);
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: RefreshIndicator(
        onRefresh: _refreshProfiles,
        child: ListView(
          padding: r.pagePadding(horizontal: 20, top: 8, bottom: 120),
          children: [
            // Header card - neumorphic
            Neumorphic(
              style: AppTheme.nConvex(radius: r.scale(20)),
              padding: EdgeInsets.all(r.scale(20)),
              child: Row(
                children: [
                  SizedBox(
                    width: r.scale(48),
                    height: r.scale(48),
                    child: Neumorphic(
                      style: AppTheme.nCircle(),
                      child: Center(
                        child: Icon(Icons.groups_rounded, color: AppTheme.primaryBlue, size: r.scale(24)),
                      ),
                    ),
                  ),
                  SizedBox(width: r.scale(14)),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Toplam ${_profiles.length} profil',
                          style: TextStyle(
                            color: AppTheme.textDark,
                            fontSize: r.scale(16),
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        SizedBox(height: r.scale(2)),
                        Text(
                          'Aktif: ${_activeProfile.name}',
                          style: TextStyle(
                            color: AppTheme.textGray,
                            fontSize: r.scale(13),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(height: r.scale(16)),

            // Profile cards - neumorphic
            ..._profiles.asMap().entries.map((entry) {
              final index = entry.key;
              final p = entry.value;
              final active = _isActive(p);

              return Neumorphic(
                style: active
                    ? AppTheme.nConcave(radius: r.scale(18))
                    : AppTheme.nConvex(radius: r.scale(18)),
                margin: EdgeInsets.only(bottom: r.scale(12)),
                padding: EdgeInsets.all(r.scale(16)),
                child: Row(
                  children: [
                    // Avatar
                    SizedBox(
                      width: r.scale(50),
                      height: r.scale(50),
                      child: Neumorphic(
                        style: active
                            ? AppTheme.nCircleConcave()
                            : AppTheme.nCircle(),
                        child: Center(
                          child: Text(
                            p.initial,
                            style: TextStyle(
                              color: active ? AppTheme.primaryBlue : AppTheme.textDark,
                              fontWeight: FontWeight.w700,
                              fontSize: r.scale(18),
                            ),
                          ),
                        ),
                      ),
                    ),
                    SizedBox(width: r.scale(14)),
                    // Info
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Flexible(
                                child: Text(
                                  p.name,
                                  style: TextStyle(
                                    fontWeight: FontWeight.w700,
                                    fontSize: r.scale(15),
                                    color: AppTheme.textDark,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              if (active) ...[
                                SizedBox(width: r.scale(8)),
                                Neumorphic(
                                  style: AppTheme.nConcave(radius: 999),
                                  padding: EdgeInsets.symmetric(horizontal: r.scale(8), vertical: r.scale(3)),
                                  child: Text(
                                    'Aktif',
                                    style: TextStyle(
                                      color: AppTheme.primaryBlue,
                                      fontSize: r.scale(11),
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ),
                              ],
                            ],
                          ),
                          SizedBox(height: r.scale(4)),
                          Text(
                            '${p.age.toInt()} ya\u015f \u2022 ${_genderText(p)} \u2022 ${p.heightCm.toInt()}cm / ${p.weightKg.toInt()}kg',
                            style: TextStyle(color: AppTheme.textGray, fontSize: r.scale(13)),
                          ),
                        ],
                      ),
                    ),
                    // Actions
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (!active)
                          IconButton(
                            tooltip: 'Profili se\u00e7',
                            icon: Icon(Icons.check_circle_outline, color: AppTheme.primaryBlue, size: r.scale(22)),
                            onPressed: () => _selectProfile(p),
                          ),
                        IconButton(
                          tooltip: 'Profili d\u00fczenle',
                          icon: Icon(Icons.edit_outlined, color: AppTheme.accentGold, size: r.scale(22)),
                          onPressed: () => _editProfile(index, p),
                        ),
                        IconButton(
                          tooltip: 'Profili sil',
                          icon: Icon(Icons.delete_outline, color: AppTheme.riskRed.withOpacity(0.7), size: r.scale(22)),
                          onPressed: () => _deleteProfile(index),
                        ),
                      ],
                    ),
                  ],
                ),
              );
            }),

            // Profil Ekle butonu
            SizedBox(height: r.scale(16)),
            Center(
              child: NeumorphicButton(
                style: AppTheme.nConvex(radius: r.scale(16)),
                onPressed: _addProfile,
                padding: EdgeInsets.symmetric(horizontal: r.scale(20), vertical: r.scale(14)),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.person_add_alt_1, color: AppTheme.primaryBlue, size: r.scale(20)),
                    SizedBox(width: r.scale(8)),
                    Text('Profil Ekle', style: TextStyle(color: AppTheme.primaryBlue, fontWeight: FontWeight.w700, fontSize: r.scale(14))),
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

class _DialogSlider extends StatelessWidget {
  final String label;
  final double value;
  final String suffix;
  final double min;
  final double max;
  final int divisions;
  final ValueChanged<double> onChanged;

  const _DialogSlider({
    required this.label,
    required this.value,
    required this.suffix,
    required this.min,
    required this.max,
    required this.divisions,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(label, style: const TextStyle(fontWeight: FontWeight.w600, color: AppTheme.textDark)),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: AppTheme.primaryBlue.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  '${value.toInt()}$suffix',
                  style: const TextStyle(color: AppTheme.primaryBlue, fontWeight: FontWeight.w700, fontSize: 13),
                ),
              ),
            ],
          ),
          Slider(
            value: value,
            min: min,
            max: max,
            divisions: divisions,
            onChanged: onChanged,
          ),
        ],
      ),
    );
  }
}
