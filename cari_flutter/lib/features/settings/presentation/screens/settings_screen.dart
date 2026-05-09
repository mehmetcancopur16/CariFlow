import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../core/constants/api_constants.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/providers/package_info_provider.dart';
import '../../../../core/theme/theme_mode_provider.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  bool _healthChecking = false;
  bool? _healthOk;
  String? _healthMessage;

  Future<void> _checkHealth() async {
    setState(() {
      _healthChecking = true;
      _healthMessage = null;
    });
    try {
      final dio = Dio(
        BaseOptions(
          connectTimeout: const Duration(seconds: 4),
          receiveTimeout: const Duration(seconds: 4),
        ),
      );
      final response = await dio.get<Map<String, dynamic>>(
        ApiConstants.healthUrl,
      );
      final ok = response.data?['status'] == 'OK';
      if (!mounted) return;
      setState(() {
        _healthOk = ok;
        _healthMessage = ok ? 'Sunucu yanit veriyor' : 'Beklenmeyen yanit';
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _healthOk = false;
        _healthMessage = 'Baglanti kurulamadi';
      });
    } finally {
      if (mounted) {
        setState(() => _healthChecking = false);
      }
    }
  }

  Future<void> _openSwagger() async {
    final uri = Uri.parse(ApiConstants.swaggerUrl);
    final ok = await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (!ok && mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Swagger acilamadi')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final themeModeAsync = ref.watch(themeModeProvider);
    final packageInfoAsync = ref.watch(packageInfoProvider);

    final gradientColors = theme.brightness == Brightness.dark
        ? [
            cs.primary.withAlpha(36),
            const Color(0xFF0F172A),
            AppColors.successColor.withAlpha(28),
          ]
        : [
            AppColors.primaryColor.withAlpha(28),
            AppColors.backgroundColor,
            AppColors.successColor.withAlpha(20),
          ];

    return Scaffold(
      body: Container(
        width: double.infinity,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: gradientColors,
            stops: const [0.0, 0.5, 1.0],
          ),
        ),
        child: SafeArea(
          child: RefreshIndicator(
            onRefresh: () async {
              ref.invalidate(packageInfoProvider);
              await _checkHealth();
            },
            child: CustomScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              slivers: [
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 20, 20, 8),
                    child: TweenAnimationBuilder<double>(
                      tween: Tween(begin: 0, end: 1),
                      duration: const Duration(milliseconds: 480),
                      curve: Curves.easeOutCubic,
                      builder: (context, t, child) => Opacity(
                        opacity: t,
                        child: Transform.translate(
                          offset: Offset(0, (1 - t) * 16),
                          child: child,
                        ),
                      ),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [cs.primary, cs.primary.withAlpha(200)],
                              ),
                              borderRadius: BorderRadius.circular(18),
                              boxShadow: [
                                BoxShadow(
                                  color: cs.primary.withAlpha(70),
                                  blurRadius: 16,
                                  offset: const Offset(0, 6),
                                ),
                              ],
                            ),
                            child: const Icon(
                              Icons.tune_rounded,
                              color: Colors.white,
                              size: 26,
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Ayarlar',
                                  style: theme.textTheme.headlineSmall
                                      ?.copyWith(fontWeight: FontWeight.w800),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'Gorunum, baglanti ve uygulama bilgileri',
                                  style: theme.textTheme.bodyMedium?.copyWith(
                                    color: theme.textTheme.bodyMedium?.color
                                        ?.withAlpha(160),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(20, 8, 20, 12),
                  sliver: SliverList(
                    delegate: SliverChildListDelegate([
                      _SettingsCard(
                        delayMs: 0,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _sectionTitle(
                              theme,
                              Icons.palette_outlined,
                              'Gorunum',
                            ),
                            const SizedBox(height: 12),
                            themeModeAsync.when(
                              loading: () => const Center(
                                child: Padding(
                                  padding: EdgeInsets.all(12),
                                  child: CircularProgressIndicator(),
                                ),
                              ),
                              error: (_, __) => const Text('Tema yuklenemedi'),
                              data: (mode) {
                                return LayoutBuilder(
                                  builder: (context, constraints) {
                                    return SizedBox(
                                      width: constraints.maxWidth,
                                      child: FittedBox(
                                        fit: BoxFit.scaleDown,
                                        alignment: Alignment.centerLeft,
                                        child: SegmentedButton<ThemeMode>(
                                          showSelectedIcon: false,
                                          segments: const [
                                            ButtonSegment(
                                              value: ThemeMode.system,
                                              label: Text('Sistem'),
                                              icon: Icon(
                                                Icons.brightness_auto_rounded,
                                              ),
                                            ),
                                            ButtonSegment(
                                              value: ThemeMode.light,
                                              label: Text('Acik'),
                                              icon: Icon(
                                                Icons.light_mode_rounded,
                                              ),
                                            ),
                                            ButtonSegment(
                                              value: ThemeMode.dark,
                                              label: Text('Koyu'),
                                              icon: Icon(
                                                Icons.dark_mode_rounded,
                                              ),
                                            ),
                                          ],
                                          selected: {mode},
                                          onSelectionChanged: (s) {
                                            ref
                                                .read(
                                                  themeModeProvider.notifier,
                                                )
                                                .setThemeMode(s.first);
                                          },
                                        ),
                                      ),
                                    );
                                  },
                                );
                              },
                            ),
                          ],
                        ),
                      ),
                      _SettingsCard(
                        delayMs: 60,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _sectionTitle(
                              theme,
                              Icons.cloud_outlined,
                              'Backend baglantisi',
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'REST API tabani (bu derleme)',
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: theme.textTheme.bodySmall?.color
                                    ?.withAlpha(150),
                              ),
                            ),
                            const SizedBox(height: 10),
                            SelectableText(
                              ApiConstants.baseUrl,
                              style: theme.textTheme.bodyMedium?.copyWith(
                                fontWeight: FontWeight.w700,
                                color: cs.primary,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              children: [
                                FilledButton.tonalIcon(
                                  onPressed: () async {
                                    await Clipboard.setData(
                                      ClipboardData(text: ApiConstants.baseUrl),
                                    );
                                    if (context.mounted) {
                                      ScaffoldMessenger.of(
                                        context,
                                      ).showSnackBar(
                                        const SnackBar(
                                          content: Text(
                                            'API adresi kopyalandi',
                                          ),
                                        ),
                                      );
                                    }
                                  },
                                  icon: const Icon(
                                    Icons.copy_rounded,
                                    size: 20,
                                  ),
                                  label: const Text('Kopyala'),
                                ),
                                FilledButton.icon(
                                  onPressed: _healthChecking
                                      ? null
                                      : _checkHealth,
                                  icon: _healthChecking
                                      ? const SizedBox(
                                          width: 18,
                                          height: 18,
                                          child: CircularProgressIndicator(
                                            strokeWidth: 2,
                                          ),
                                        )
                                      : const Icon(Icons.monitor_heart_rounded),
                                  label: const Text('Sunucu durumu'),
                                ),
                                OutlinedButton.icon(
                                  onPressed: _openSwagger,
                                  icon: const Icon(Icons.menu_book_outlined),
                                  label: const Text('Swagger'),
                                ),
                              ],
                            ),
                            if (_healthOk != null) ...[
                              const SizedBox(height: 12),
                              Row(
                                children: [
                                  Icon(
                                    _healthOk!
                                        ? Icons.check_circle_rounded
                                        : Icons.error_outline_rounded,
                                    color: _healthOk!
                                        ? AppColors.successColor
                                        : AppColors.dangerColor,
                                    size: 22,
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      _healthMessage ?? '',
                                      style: theme.textTheme.bodyMedium
                                          ?.copyWith(
                                            fontWeight: FontWeight.w600,
                                          ),
                                    ),
                                  ),
                                ],
                              ),
                              SelectableText(
                                ApiConstants.healthUrl,
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: theme.textTheme.bodySmall?.color
                                      ?.withAlpha(140),
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                      _SettingsCard(
                        delayMs: 120,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _sectionTitle(
                              theme,
                              Icons.person_outline_rounded,
                              'Hesap',
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Kurum bilgileri, sifre ve oturum',
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: theme.textTheme.bodySmall?.color
                                    ?.withAlpha(150),
                              ),
                            ),
                            const SizedBox(height: 8),
                            ListTile(
                              contentPadding: EdgeInsets.zero,
                              leading: CircleAvatar(
                                backgroundColor: cs.primary.withAlpha(36),
                                child: Icon(
                                  Icons.badge_rounded,
                                  color: cs.primary,
                                ),
                              ),
                              title: const Text('Profilim'),
                              subtitle: const Text(
                                'Ticari bilgiler ve sifre degisimi',
                              ),
                              trailing: const Icon(Icons.chevron_right_rounded),
                              onTap: () => context.go('/profile'),
                            ),
                          ],
                        ),
                      ),
                      _SettingsCard(
                        delayMs: 180,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _sectionTitle(
                              theme,
                              Icons.info_outline_rounded,
                              'Uygulama',
                            ),
                            const SizedBox(height: 12),
                            packageInfoAsync.when(
                              loading: () => const LinearProgressIndicator(),
                              error: (_, __) =>
                                  const Text('Surum bilgisi alinamadi'),
                              data: (info) {
                                return Column(
                                  children: [
                                    _tile(
                                      theme,
                                      icon: Icons.tag_rounded,
                                      title: 'Surum',
                                      subtitle:
                                          '${info.version} (${info.buildNumber})',
                                    ),
                                    const Divider(height: 22),
                                    _tile(
                                      theme,
                                      icon: Icons.devices_rounded,
                                      title: 'Platform',
                                      subtitle: kIsWeb
                                          ? 'Web'
                                          : defaultTargetPlatform.name,
                                    ),
                                  ],
                                );
                              },
                            ),
                          ],
                        ),
                      ),
                      _SettingsCard(
                        delayMs: 240,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _sectionTitle(
                              theme,
                              Icons.shield_outlined,
                              'Guvenlik',
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Koklu veya jailbreak\'li cihazlarda uygulama '
                              'guvenlik nedeniyle acilmayabilir. Token\'lar '
                              'guvenli depolamada tutulur.',
                              style: theme.textTheme.bodySmall?.copyWith(
                                height: 1.45,
                                color: theme.textTheme.bodySmall?.color
                                    ?.withAlpha(160),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),
                    ]),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  static Widget _sectionTitle(ThemeData theme, IconData icon, String title) {
    return Row(
      children: [
        Icon(icon, color: theme.colorScheme.primary, size: 22),
        const SizedBox(width: 8),
        Text(
          title,
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w800,
          ),
        ),
      ],
    );
  }

  static Widget _tile(
    ThemeData theme, {
    required IconData icon,
    required String title,
    required String subtitle,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, color: theme.textTheme.bodyMedium?.color?.withAlpha(160)),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: const TextStyle(fontWeight: FontWeight.w700)),
              const SizedBox(height: 4),
              Text(
                subtitle,
                style: TextStyle(
                  color: theme.textTheme.bodyMedium?.color?.withAlpha(160),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _SettingsCard extends StatelessWidget {
  const _SettingsCard({required this.child, this.delayMs = 0});

  final Widget child;
  final int delayMs;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: TweenAnimationBuilder<double>(
        tween: Tween(begin: 0, end: 1),
        duration: Duration(milliseconds: 380 + delayMs),
        curve: Curves.easeOutCubic,
        builder: (context, t, _) {
          return Opacity(
            opacity: t,
            child: Transform.translate(
              offset: Offset(0, (1 - t) * 12),
              child: Material(
                elevation: 0,
                color: cs.surfaceContainerHighest.withAlpha(
                  Theme.of(context).brightness == Brightness.dark ? 80 : 120,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                  side: BorderSide(
                    color: cs.primary.withAlpha(
                      Theme.of(context).brightness == Brightness.dark ? 50 : 35,
                    ),
                  ),
                ),
                child: Padding(padding: const EdgeInsets.all(18), child: child),
              ),
            ),
          );
        },
      ),
    );
  }
}
