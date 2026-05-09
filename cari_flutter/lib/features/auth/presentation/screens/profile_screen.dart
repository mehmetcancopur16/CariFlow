import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/constants/app_colors.dart';
import '../providers/auth_provider.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final auth = ref.watch(authNotifierProvider);
    final theme = Theme.of(context);

    return Scaffold(
      body: Container(
        width: double.infinity,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              AppColors.primaryColor.withAlpha(26),
              AppColors.backgroundColor,
              AppColors.successColor.withAlpha(18),
            ],
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 480),
                child: auth.when(
                  loading: () => const Padding(
                    padding: EdgeInsets.only(top: 80),
                    child: Center(child: CircularProgressIndicator()),
                  ),
                  error: (_, __) => const Text('Profil yuklenemedi'),
                  data: (state) {
                    final email = state.user?.email ?? '';
                    final id = state.user?.id ?? '';

                    return TweenAnimationBuilder<double>(
                      tween: Tween(begin: 0.94, end: 1),
                      duration: const Duration(milliseconds: 450),
                      curve: Curves.easeOutCubic,
                      builder: (context, s, child) =>
                          Transform.scale(scale: s, child: child),
                      child: Column(
                        children: [
                          const SizedBox(height: 24),
                          Hero(
                            tag: 'profile_avatar',
                            child: CircleAvatar(
                              radius: 52,
                              backgroundColor: AppColors.primaryColor.withAlpha(
                                40,
                              ),
                              child: Text(
                                email.isNotEmpty ? email[0].toUpperCase() : '?',
                                style: const TextStyle(
                                  fontSize: 40,
                                  fontWeight: FontWeight.w800,
                                  color: AppColors.primaryColor,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 20),
                          Text(
                            'Hesabim',
                            style: theme.textTheme.headlineSmall?.copyWith(
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            email.isNotEmpty
                                ? email
                                : 'E-posta bu oturumda gorunmuyor (yeniden giris yapabilirsiniz)',
                            textAlign: TextAlign.center,
                            style: theme.textTheme.bodyLarge?.copyWith(
                              color: AppColors.textColor.withAlpha(180),
                            ),
                          ),
                          if (id.isNotEmpty) ...[
                            const SizedBox(height: 8),
                            SelectableText(
                              'Kullanici ID: $id',
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: AppColors.textColor.withAlpha(120),
                              ),
                            ),
                          ],
                          const SizedBox(height: 32),
                          Card(
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(18),
                              side: BorderSide(
                                color: AppColors.primaryColor.withAlpha(28),
                              ),
                            ),
                            child: Column(
                              children: [
                                ListTile(
                                  leading: const Icon(
                                    Icons.verified_user_outlined,
                                    color: AppColors.primaryColor,
                                  ),
                                  title: const Text('Guvenlik'),
                                  subtitle: const Text(
                                    'Cikis yaparak oturumu sonlandirin',
                                  ),
                                ),
                                const Divider(height: 1),
                                ListTile(
                                  leading: const Icon(
                                    Icons.logout_rounded,
                                    color: AppColors.dangerColor,
                                  ),
                                  title: const Text('Cikis Yap'),
                                  onTap: () async {
                                    await ref
                                        .read(authNotifierProvider.notifier)
                                        .logout();
                                  },
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
