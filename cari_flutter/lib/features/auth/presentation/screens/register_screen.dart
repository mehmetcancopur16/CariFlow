import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/network/api_error_mapper.dart';
import '../providers/auth_provider.dart';

class RegisterScreen extends ConsumerStatefulWidget {
  const RegisterScreen({super.key});

  @override
  ConsumerState<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends ConsumerState<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  double _passwordStrength = 0;
  String _passwordHint = 'Sifre gucu: zayif';

  @override
  void initState() {
    super.initState();
    _passwordController.addListener(_updatePasswordStrength);
    ref.listenManual<AsyncValue<AuthState>>(authNotifierProvider, (_, next) {
      next.whenOrNull(
        error: (error, _) {
          if (!mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(ApiErrorMapper.toMessage(error))),
          );
        },
      );
    });
  }

  @override
  void dispose() {
    _passwordController.removeListener(_updatePasswordStrength);
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  void _updatePasswordStrength() {
    final password = _passwordController.text.trim();
    final hasMinLength = password.length >= 8;
    final hasUppercase = RegExp(r'[A-Z]').hasMatch(password);
    final hasLowercase = RegExp(r'[a-z]').hasMatch(password);
    final hasDigit = RegExp(r'\d').hasMatch(password);
    final hasSpecial = RegExp(r'[^A-Za-z0-9]').hasMatch(password);
    final checks = [
      hasMinLength,
      hasUppercase,
      hasLowercase,
      hasDigit,
      hasSpecial,
    ];
    final passedChecks = checks.where((c) => c).length;
    final strength = passedChecks / checks.length;

    setState(() {
      _passwordStrength = strength;
      if (strength < 0.4) {
        _passwordHint = 'Sifre gucu: zayif';
      } else if (strength < 0.8) {
        _passwordHint = 'Sifre gucu: orta';
      } else {
        _passwordHint = 'Sifre gucu: guclu';
      }
    });
  }

  bool _isPasswordStrong(String password) {
    return password.length >= 8 &&
        RegExp(r'[A-Z]').hasMatch(password) &&
        RegExp(r'[a-z]').hasMatch(password) &&
        RegExp(r'\d').hasMatch(password) &&
        RegExp(r'[^A-Za-z0-9]').hasMatch(password);
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    await ref
        .read(authNotifierProvider.notifier)
        .register(
          _emailController.text.trim(),
          _passwordController.text.trim(),
        );
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authNotifierProvider);
    final isLoading = authState.isLoading;
    final theme = Theme.of(context);
    final strengthColor = _passwordStrength < 0.4
        ? AppColors.dangerColor
        : _passwordStrength < 0.8
        ? const Color(0xFFF59E0B)
        : AppColors.successColor;

    return Scaffold(
      body: SafeArea(
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                AppColors.primaryColor.withAlpha(24),
                Colors.white,
                AppColors.successColor.withAlpha(22),
              ],
            ),
          ),
          child: Center(
            child: TweenAnimationBuilder<double>(
              tween: Tween<double>(begin: 0.9, end: 1),
              duration: const Duration(milliseconds: 600),
              curve: Curves.easeOutCubic,
              builder: (context, scale, child) {
                return Transform.scale(scale: scale, child: child);
              },
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 460),
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      color: Colors.white.withAlpha(245),
                      borderRadius: BorderRadius.circular(28),
                      border: Border.all(
                        color: AppColors.primaryColor.withAlpha(35),
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.primaryColor.withAlpha(22),
                          blurRadius: 28,
                          offset: const Offset(0, 18),
                        ),
                      ],
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(28),
                      child: Form(
                        key: _formKey,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: AppColors.successColor.withAlpha(30),
                                    borderRadius: BorderRadius.circular(14),
                                  ),
                                  child: const Icon(
                                    Icons.person_add_rounded,
                                    color: AppColors.successColor,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                const Text(
                                  'Kayit Ol',
                                  style: TextStyle(
                                    fontSize: 30,
                                    fontWeight: FontWeight.w800,
                                    color: AppColors.textColor,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 10),
                            Text(
                              'Yeni hesap olustur ve CariFlow\'a basla',
                              style: theme.textTheme.bodyMedium?.copyWith(
                                color: AppColors.textColor.withAlpha(170),
                              ),
                            ),
                            const SizedBox(height: 24),
                            TextFormField(
                              controller: _emailController,
                              keyboardType: TextInputType.emailAddress,
                              decoration: const InputDecoration(
                                labelText: 'E-posta',
                                border: OutlineInputBorder(),
                                prefixIcon: Icon(Icons.mail_outline_rounded),
                                filled: true,
                                fillColor: Colors.white,
                              ),
                              validator: (value) {
                                final email = value?.trim() ?? '';
                                if (email.isEmpty) return 'E-posta bos olamaz';
                                final emailRegex = RegExp(
                                  r'^[^@\s]+@[^@\s]+\.[^@\s]+$',
                                );
                                if (!emailRegex.hasMatch(email)) {
                                  return 'Gecerli bir e-posta girin';
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: 16),
                            TextFormField(
                              controller: _passwordController,
                              obscureText: _obscurePassword,
                              decoration: InputDecoration(
                                labelText: 'Sifre',
                                border: const OutlineInputBorder(),
                                prefixIcon: const Icon(Icons.key_rounded),
                                suffixIcon: IconButton(
                                  tooltip: _obscurePassword
                                      ? 'Sifreyi goster'
                                      : 'Sifreyi gizle',
                                  onPressed: () {
                                    setState(() {
                                      _obscurePassword = !_obscurePassword;
                                    });
                                  },
                                  icon: Icon(
                                    _obscurePassword
                                        ? Icons.visibility_outlined
                                        : Icons.visibility_off_outlined,
                                  ),
                                ),
                                filled: true,
                                fillColor: Colors.white,
                              ),
                              validator: (value) {
                                final password = value?.trim() ?? '';
                                if (password.isEmpty) return 'Sifre bos olamaz';
                                if (!_isPasswordStrong(password)) {
                                  return 'En az 8 karakter, buyuk/kucuk harf, rakam ve ozel karakter gerekli';
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: 8),
                            ClipRRect(
                              borderRadius: BorderRadius.circular(99),
                              child: LinearProgressIndicator(
                                minHeight: 9,
                                value: _passwordStrength,
                                backgroundColor: Colors.black.withAlpha(15),
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  strengthColor,
                                ),
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              _passwordHint,
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: strengthColor,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 16),
                            TextFormField(
                              controller: _confirmPasswordController,
                              obscureText: _obscureConfirmPassword,
                              decoration: InputDecoration(
                                labelText: 'Sifre Tekrari',
                                border: const OutlineInputBorder(),
                                prefixIcon: const Icon(Icons.shield_rounded),
                                suffixIcon: IconButton(
                                  tooltip: _obscureConfirmPassword
                                      ? 'Sifreyi goster'
                                      : 'Sifreyi gizle',
                                  onPressed: () {
                                    setState(() {
                                      _obscureConfirmPassword =
                                          !_obscureConfirmPassword;
                                    });
                                  },
                                  icon: Icon(
                                    _obscureConfirmPassword
                                        ? Icons.visibility_outlined
                                        : Icons.visibility_off_outlined,
                                  ),
                                ),
                                filled: true,
                                fillColor: Colors.white,
                              ),
                              validator: (value) {
                                final confirmation = value?.trim() ?? '';
                                if (confirmation.isEmpty) {
                                  return 'Sifre tekrari bos olamaz';
                                }
                                if (confirmation !=
                                    _passwordController.text.trim()) {
                                  return 'Sifreler eslesmiyor';
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: 22),
                            SizedBox(
                              width: double.infinity,
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 220),
                                curve: Curves.easeOut,
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(14),
                                  boxShadow: isLoading
                                      ? const []
                                      : [
                                          BoxShadow(
                                            color: AppColors.successColor
                                                .withAlpha(75),
                                            blurRadius: 14,
                                            offset: const Offset(0, 7),
                                          ),
                                        ],
                                ),
                                child: FilledButton(
                                  onPressed: isLoading ? null : _submit,
                                  style: FilledButton.styleFrom(
                                    backgroundColor: AppColors.primaryColor,
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 14,
                                    ),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(14),
                                    ),
                                  ),
                                  child: isLoading
                                      ? const SizedBox(
                                          width: 22,
                                          height: 22,
                                          child: CircularProgressIndicator(
                                            strokeWidth: 2.5,
                                            color: Colors.white,
                                          ),
                                        )
                                      : const Text('Kayit Ol'),
                                ),
                              ),
                            ),
                            const SizedBox(height: 10),
                            Center(
                              child: TextButton.icon(
                                onPressed: () => context.go('/login'),
                                icon: const Icon(Icons.login_rounded),
                                label: const Text(
                                  'Zaten hesabin var mi? Giris Yap',
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
