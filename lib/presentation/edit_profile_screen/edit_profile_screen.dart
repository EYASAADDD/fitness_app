import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../core/user_profile_store.dart';
import '../../theme/app_theme.dart';

class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late final TextEditingController _emailController;
  late final TextEditingController _ageController;
  late final TextEditingController _weightController;
  late final TextEditingController _heightController;
  final Set<String> _selectedFocuses = {};
  bool _isSaving = false;

  static const List<String> _focusOptions = [
    'Strength', 'Cardio', 'Mobility',
    'Weight loss', 'Muscle gain', 'Posture',
    'Nutrition', 'Recovery',
  ];

  @override
  void initState() {
    super.initState();
    _nameController   = TextEditingController(text: AppUserProfile.defaults.name);
    _emailController  = TextEditingController();
    _ageController    = TextEditingController(text: AppUserProfile.defaults.age.toString());
    _weightController = TextEditingController(text: AppUserProfile.defaults.weight.toStringAsFixed(0));
    _heightController = TextEditingController(text: AppUserProfile.defaults.height.toStringAsFixed(0));
    _selectedFocuses.addAll({'Strength', 'Nutrition'});
    _loadProfile();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _ageController.dispose();
    _weightController.dispose();
    _heightController.dispose();
    super.dispose();
  }

  Future<void> _loadProfile() async {
    final profile = await UserProfileStore.load();
    if (!mounted) return;
    setState(() {
      _nameController.text   = profile.name;
      _emailController.text  = profile.email;
      _ageController.text    = profile.age.toString();
      _weightController.text = profile.weight.toStringAsFixed(0);
      _heightController.text = profile.height.toStringAsFixed(0);
      _selectedFocuses..clear()..addAll(profile.diseases);
    });
  }

  double _computeBmi(double weight, double height) {
    if (height <= 0) return AppUserProfile.defaults.bmi;
    return weight / ((height / 100) * (height / 100));
  }

  String _bmiStatus(double bmi) {
    if (bmi < 18.5) return 'Lean';
    if (bmi < 25.0) return 'Ready';
    if (bmi < 30.0) return 'Build';
    return 'Reduce';
  }

  void _toggleFocus(String focus) {
    setState(() {
      if (_selectedFocuses.contains(focus)) {
        _selectedFocuses.remove(focus);
      } else {
        _selectedFocuses.add(focus);
      }
    });
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isSaving = true);

    final weight = double.tryParse(_weightController.text) ?? AppUserProfile.defaults.weight;
    final height = double.tryParse(_heightController.text) ?? AppUserProfile.defaults.height;
    final bmi    = _computeBmi(weight, height);

    await UserProfileStore.save(
      AppUserProfile(
        name: _nameController.text.trim().isEmpty
            ? AppUserProfile.defaults.name
            : _nameController.text.trim(),
        email:     _emailController.text.trim(),
        bmi:       bmi,
        bmiStatus: _bmiStatus(bmi),
        diseases:  _selectedFocuses.toList(),
        avatarUrl: '',
        age:    int.tryParse(_ageController.text) ?? AppUserProfile.defaults.age,
        weight: weight,
        height: height,
      ),
    );

    if (!mounted) return;
    setState(() => _isSaving = false);
    Navigator.pop(context, true);
  }

  @override
  Widget build(BuildContext context) {
    // ── Respecte le thème actuel ──────────────────────────────────────────
    final isDark  = Theme.of(context).brightness == Brightness.dark;
    final bg      = isDark ? AppTheme.bgPage      : const Color(0xFFF5F5F5);
    final cardBg  = isDark ? AppTheme.bgCard       : Colors.white;
    final textCol = isDark ? AppTheme.textPrimary  : const Color(0xFF111111);

    return Scaffold(
      backgroundColor: bg,
      appBar: AppBar(
        backgroundColor: bg,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_rounded, size: 20, color: textCol),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Edit fitness profile',
          style: GoogleFonts.inter(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: textCol,
          ),
        ),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
          children: [
            _buildHeroCard(isDark: isDark, cardBg: cardBg, textCol: textCol),
            const SizedBox(height: 18),
            _field(controller: _nameController,   label: 'Full name',    textCol: textCol),
            const SizedBox(height: 12),
            _field(controller: _emailController,  label: 'Email',        textCol: textCol, keyboardType: TextInputType.emailAddress),
            const SizedBox(height: 12),
            Row(children: [
              Expanded(child: _field(controller: _ageController,    label: 'Age',         textCol: textCol, keyboardType: TextInputType.number)),
              const SizedBox(width: 12),
              Expanded(child: _field(controller: _weightController, label: 'Weight (kg)', textCol: textCol, keyboardType: TextInputType.number)),
            ]),
            const SizedBox(height: 12),
            _field(controller: _heightController, label: 'Height (cm)', textCol: textCol, keyboardType: TextInputType.number),
            const SizedBox(height: 18),
            _buildFocusSection(isDark: isDark, cardBg: cardBg, textCol: textCol),
            const SizedBox(height: 18),
            SizedBox(
              height: 54,
              child: ElevatedButton(
                onPressed: _isSaving ? null : _save,
                child: _isSaving
                    ? const SizedBox(
                        width: 20, height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.black),
                      )
                    : const Text('Save changes'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeroCard({
    required bool isDark,
    required Color cardBg,
    required Color textCol,
  }) {
    final bmi = _computeBmi(
      double.tryParse(_weightController.text) ?? AppUserProfile.defaults.weight,
      double.tryParse(_heightController.text) ?? AppUserProfile.defaults.height,
    );

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: isDark ? AppTheme.bgCard : Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: AppTheme.fitGreen.withAlpha(80),
        ),
      ),
      child: Row(children: [
        Container(
          width: 54, height: 54,
          decoration: BoxDecoration(
            color: AppTheme.fitGreen.withAlpha(25),
            borderRadius: BorderRadius.circular(16),
          ),
          child: const Icon(Icons.monitor_weight_rounded, color: AppTheme.fitGreen),
        ),
        const SizedBox(width: 14),
        Expanded(child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'BMI preview ${bmi.toStringAsFixed(1)}',
              style: GoogleFonts.inter(
                fontSize: 16, fontWeight: FontWeight.w700, color: textCol,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Update your data and keep your fitness coach synced.',
              style: GoogleFonts.inter(fontSize: 12, color: AppTheme.textSecondary),
            ),
          ],
        )),
      ]),
    );
  }

  Widget _buildFocusSection({
    required bool isDark,
    required Color cardBg,
    required Color textCol,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Main goals',
          style: GoogleFonts.inter(
            fontSize: 17, fontWeight: FontWeight.w700, color: textCol,
          ),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 10,
          runSpacing: 10,
          children: _focusOptions.map((focus) {
            final isSelected = _selectedFocuses.contains(focus);
            return GestureDetector(
              onTap: () => _toggleFocus(focus),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 9),
                decoration: BoxDecoration(
                  color: isSelected
                      ? AppTheme.fitGreen
                      : (isDark ? AppTheme.bgCard : Colors.white),
                  borderRadius: BorderRadius.circular(999),
                  border: Border.all(
                    color: isSelected
                        ? AppTheme.fitGreen
                        : AppTheme.borderLight,
                  ),
                ),
                child: Text(
                  focus,
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: isSelected ? Colors.black : AppTheme.textSecondary,
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _field({
    required TextEditingController controller,
    required String label,
    required Color textCol,
    TextInputType keyboardType = TextInputType.text,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      style: GoogleFonts.inter(fontSize: 14, color: textCol),
      decoration: InputDecoration(labelText: label),
      validator: (value) =>
          (value == null || value.trim().isEmpty) ? 'Required' : null,
    );
  }
}
