import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/network/api_error_mapper.dart';
import '../providers/auth_provider.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;

  @override
  void initState() {
    super.initState();
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
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    await ref
        .read(authNotifierProvider.notifier)
        .login(_emailController.text.trim(), _passwordController.text.trim());
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authNotifierProvider);
    final isLoading = authState.isLoading;
    final theme = Theme.of(context);

    return Scaffold(
      body: SafeArea(
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                AppColors.primaryColor.withAlpha(28),
                Colors.white,
                AppColors.successColor.withAlpha(20),
              ],
            ),
          ),
          child: Center(
            child: TweenAnimationBuilder<double>(
              tween: Tween<double>(begin: 0.92, end: 1),
              duration: const Duration(milliseconds: 550),
              curve: Curves.easeOutCubic,
              builder: (context, scale, child) {
                return Transform.scale(scale: scale, child: child);
              },
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 440),
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      color: Colors.white.withAlpha(242),
                      borderRadius: BorderRadius.circular(28),
                      border: Border.all(
                        color: AppColors.primaryColor.withAlpha(35),
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.primaryColor.withAlpha(20),
                          blurRadius: 28,
                          offset: const Offset(0, 16),
                        ),
                      ],
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(28),
                      child: Form(
                        key: _formKey,
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: AppColors.primaryColor.withAlpha(28),
                                    borderRadius: BorderRadius.circular(14),
                                  ),
                                  child: const Icon(
                                    Icons.lock_open_rounded,
                                    color: AppColors.primaryColor,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                const Text(
                                  'CariFlow',
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
                              'Hesabina giris yaparak devam et',
                              style: theme.textTheme.bodyMedium?.copyWith(
                                color: AppColors.textColor.withAlpha(170),
                              ),
                            ),
                            const SizedBox(height: 26),
                            TextFormField(
                              controller: _emailController,
                              keyboardType: TextInputType.emailAddress,
                              decoration: InputDecoration(
                                labelText: 'E-posta',
                                border: const OutlineInputBorder(),
                                prefixIcon: const Icon(
                                  Icons.mail_outline_rounded,
                                ),
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
                                if ((value ?? '').trim().isEmpty) {
                                  return 'Sifre bos olamaz';
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
                                            color: AppColors.primaryColor
                                                .withAlpha(70),
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
                                      : const Text('Giris Yap'),
                                ),
                              ),
                            ),
                            const SizedBox(height: 10),
                            Center(
                              child: TextButton.icon(
                                onPressed: () => context.go('/register'),
                                icon: const Icon(
                                  Icons.person_add_alt_1_rounded,
                                ),
                                label: const Text('Hesabin yok mu? Kayit Ol'),
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
