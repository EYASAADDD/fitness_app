import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../core/user_profile_store.dart';
import '../../routes/app_routes.dart';
import '../../theme/app_theme.dart';

class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController    = TextEditingController();
  final _emailController   = TextEditingController();
  final _passwordController = TextEditingController();
  final _ageController     = TextEditingController();
  final _weightController  = TextEditingController();
  final _heightController  = TextEditingController();

  // ── Dropdown objectifs prédéfinis ─────────────────────────────────────────
  static const List<String> _goals = [
    'Get Fitter',
    'Gain Weight',
    'Lose Weight',
    'Build Muscles',
    'Improve Endurance',
    'Others',
  ];
  String _selectedGoal = 'Get Fitter';

  bool _isLogin = true;
  bool _loading = false;
  bool _obscure = true;
  String? _error;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _ageController.dispose();
    _weightController.dispose();
    _heightController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() { _loading = true; _error = null; });

    try {
      final email    = _emailController.text.trim();
      final password = _passwordController.text;

      if (_isLogin) {
        await FirebaseAuth.instance.signInWithEmailAndPassword(
          email: email, password: password,
        );
      } else {
        await FirebaseAuth.instance.createUserWithEmailAndPassword(
          email: email, password: password,
        );
        await UserProfileStore.save(
          AppUserProfile.defaults.copyWith(
            name: _nameController.text.trim().isEmpty
                ? AppUserProfile.defaults.name
                : _nameController.text.trim(),
            email: email,
            age:    int.tryParse(_ageController.text)    ?? AppUserProfile.defaults.age,
            weight: double.tryParse(_weightController.text) ?? AppUserProfile.defaults.weight,
            height: double.tryParse(_heightController.text) ?? AppUserProfile.defaults.height,
            goal: _selectedGoal,
          ),
        );
      }

      if (!mounted) return;
      Navigator.pushNamedAndRemoveUntil(
        context, AppRoutes.homeScreen, (route) => false,
      );
    } on FirebaseAuthException catch (e) {
      setState(() => _error = _friendlyError(e.code));
    } catch (_) {
      setState(() => _error = 'Unexpected error. Please try again.');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _resetPassword() async {
    final email = _emailController.text.trim();
    if (email.isEmpty) {
      setState(() => _error = 'Enter your email first.');
      return;
    }
    try {
      await FirebaseAuth.instance.sendPasswordResetEmail(email: email);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Password reset email sent.')),
      );
    } catch (_) {
      setState(() => _error = 'Unable to send reset email.');
    }
  }

  String _friendlyError(String code) {
    switch (code) {
      case 'user-not-found':      return 'No account found with this email.';
      case 'wrong-password':      return 'Incorrect password.';
      case 'email-already-in-use': return 'This email is already registered.';
      case 'weak-password':       return 'Password must be at least 6 characters.';
      case 'invalid-email':       return 'Invalid email address.';
      case 'too-many-requests':   return 'Too many attempts. Try again later.';
      default:                    return 'Authentication error. Please try again.';
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark  = Theme.of(context).brightness == Brightness.dark;
    final bg      = isDark ? AppTheme.bgPage : const Color(0xFFF5F5F5);
    final cardBg  = isDark ? AppTheme.bgCard : Colors.white;
    final textCol = isDark ? AppTheme.textPrimary : const Color(0xFF111111);

    return Scaffold(
      backgroundColor: bg,
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(24, 32, 24, 32),
          children: [
            // ── Logo ──────────────────────────────────────────────────────
            Center(
              child: Container(
                width: 72, height: 72,
                decoration: BoxDecoration(
                  color: AppTheme.fitGreen.withAlpha(25),
                  borderRadius: BorderRadius.circular(22),
                  border: Border.all(color: AppTheme.fitGreen.withAlpha(80)),
                ),
                child: const Icon(Icons.fitness_center_rounded,
                    color: AppTheme.fitGreen, size: 36),
              ),
            ),
            const SizedBox(height: 20),
            Text('Smart AI Fitness',
                textAlign: TextAlign.center,
                style: GoogleFonts.inter(
                    fontSize: 26, fontWeight: FontWeight.w800, color: textCol)),
            Text('Coach',
                textAlign: TextAlign.center,
                style: GoogleFonts.inter(
                    fontSize: 26, fontWeight: FontWeight.w800,
                    color: AppTheme.fitGreen)),
            const SizedBox(height: 8),
            Text(
              'Sign in or create an account to track your\nworkouts and nutrition.',
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(
                  fontSize: 13, color: AppTheme.textSecondary, height: 1.5),
            ),
            const SizedBox(height: 28),

            // ── Tabs Login / Register ──────────────────────────────────────
            Container(
              height: 48,
              decoration: BoxDecoration(
                color: cardBg,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: AppTheme.borderLight),
              ),
              child: Row(
                children: [
                  _tab('Login',    _isLogin,  () => setState(() => _isLogin = true)),
                  _tab('Register', !_isLogin, () => setState(() => _isLogin = false)),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // ── Formulaire ─────────────────────────────────────────────────
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: cardBg,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: AppTheme.borderLight),
              ),
              child: Form(
                key: _formKey,
                child: Column(
                  children: [
                    // Champs Register uniquement
                    if (!_isLogin) ...[
                      _field(_nameController, 'Full Name',
                          Icons.person_outline_rounded,
                          validator: (v) => (v == null || v.trim().isEmpty)
                              ? 'Name is required.' : null),
                      const SizedBox(height: 14),
                      _field(_ageController, 'Age', Icons.cake_outlined,
                          keyboardType: TextInputType.number),
                      const SizedBox(height: 14),
                      Row(children: [
                        Expanded(child: _field(_weightController, 'Weight (kg)',
                            Icons.monitor_weight_outlined,
                            keyboardType: TextInputType.number)),
                        const SizedBox(width: 12),
                        Expanded(child: _field(_heightController, 'Height (cm)',
                            Icons.height_rounded,
                            keyboardType: TextInputType.number)),
                      ]),
                      const SizedBox(height: 14),
                      // ── Dropdown objectifs ─────────────────────────────
                      DropdownButtonFormField<String>(
                        value: _selectedGoal,
                        dropdownColor: cardBg,
                        style: GoogleFonts.inter(color: textCol, fontSize: 14),
                        decoration: InputDecoration(
                          labelText: 'Fitness Goal',
                          prefixIcon: const Icon(Icons.flag_outlined, size: 20),
                        ),
                        items: _goals.map((g) =>
                            DropdownMenuItem(value: g, child: Text(g))).toList(),
                        onChanged: (v) =>
                            setState(() => _selectedGoal = v ?? _selectedGoal),
                      ),
                      const SizedBox(height: 14),
                    ],

                    // Email
                    _field(_emailController, 'Email', Icons.email_outlined,
                        keyboardType: TextInputType.emailAddress,
                        validator: (v) => (v == null || v.trim().isEmpty)
                            ? 'Email is required.' : null),
                    const SizedBox(height: 14),

                    // Password
                    TextFormField(
                      controller: _passwordController,
                      obscureText: _obscure,
                      style: GoogleFonts.inter(color: textCol),
                      decoration: InputDecoration(
                        labelText: 'Password',
                        prefixIcon: const Icon(Icons.lock_outline_rounded, size: 20),
                        suffixIcon: IconButton(
                          onPressed: () => setState(() => _obscure = !_obscure),
                          icon: Icon(_obscure
                              ? Icons.visibility_outlined
                              : Icons.visibility_off_outlined,
                              size: 20),
                        ),
                      ),
                      validator: (v) => (v == null || v.length < 6)
                          ? 'Password must be at least 6 characters.' : null,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),

            // Forgot password (login only)
            if (_isLogin)
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: _resetPassword,
                  child: Text('Forgot password?',
                      style: GoogleFonts.inter(
                          fontSize: 13, color: AppTheme.fitGreen,
                          fontWeight: FontWeight.w600)),
                ),
              ),

            // Erreur
            if (_error != null) ...[
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                decoration: BoxDecoration(
                  color: AppTheme.statusRed.withAlpha(20),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: AppTheme.statusRed.withAlpha(80)),
                ),
                child: Row(children: [
                  const Icon(Icons.error_outline_rounded,
                      color: AppTheme.statusRed, size: 18),
                  const SizedBox(width: 8),
                  Expanded(child: Text(_error!,
                      style: GoogleFonts.inter(
                          color: AppTheme.statusRed, fontSize: 13))),
                ]),
              ),
            ],
            const SizedBox(height: 20),

            // Bouton principal
            SizedBox(
              height: 54,
              child: ElevatedButton(
                onPressed: _loading ? null : _submit,
                child: _loading
                    ? const SizedBox(width: 20, height: 20,
                        child: CircularProgressIndicator(
                            strokeWidth: 2.5, color: Colors.black))
                    : Text(_isLogin ? 'Sign In' : 'Create Account',
                        style: GoogleFonts.inter(
                            fontSize: 16, fontWeight: FontWeight.w700)),
              ),
            ),
            // ── "Continue without account" supprimé ───────────────────────
          ],
        ),
      ),
    );
  }

  Widget _tab(String label, bool selected, VoidCallback onTap) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          margin: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            color: selected ? AppTheme.fitGreen : Colors.transparent,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Center(
            child: Text(label,
                style: GoogleFonts.inter(
                    fontSize: 14, fontWeight: FontWeight.w700,
                    color: selected ? Colors.black : AppTheme.textHint)),
          ),
        ),
      ),
    );
  }

  Widget _field(
    TextEditingController ctrl,
    String label,
    IconData icon, {
    TextInputType keyboardType = TextInputType.text,
    String? Function(String?)? validator,
  }) {
    final isDark  = Theme.of(context).brightness == Brightness.dark;
    final textCol = isDark ? AppTheme.textPrimary : const Color(0xFF111111);
    return TextFormField(
      controller: ctrl,
      keyboardType: keyboardType,
      style: GoogleFonts.inter(color: textCol),
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, size: 20),
      ),
      validator: validator,
    );
  }
}
