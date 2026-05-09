import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/security/security_service.dart';
import 'core/theme/app_theme.dart';
import 'core/theme/theme_mode_provider.dart';
import 'router/app_router.dart';
import 'shared/widgets/security_block_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final compromised = await SecurityService.isDeviceCompromised();

  if (compromised) {
    runApp(const SecurityBlockApp());
    return;
  }

  runApp(const ProviderScope(child: CariFlowApp()));
}

class CariFlowApp extends ConsumerWidget {
  const CariFlowApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(appRouterProvider);
    final themeModeAsync = ref.watch(themeModeProvider);

    return MaterialApp.router(
      title: 'CariFlow',
      debugShowCheckedModeBanner: false,
      themeMode: themeModeAsync.when(
        data: (m) => m,
        loading: () => ThemeMode.system,
        error: (_, __) => ThemeMode.system,
      ),
      theme: AppTheme.light(),
      darkTheme: AppTheme.dark(),
      routerConfig: router,
    );
  }
}
