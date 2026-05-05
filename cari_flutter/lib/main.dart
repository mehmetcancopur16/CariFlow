import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/constants/app_colors.dart';
import 'core/security/security_service.dart';
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

    final colorScheme =
        ColorScheme.fromSeed(
          seedColor: AppColors.primaryColor,
          brightness: Brightness.light,
        ).copyWith(
          primary: AppColors.primaryColor,
          secondary: AppColors.successColor,
          error: AppColors.dangerColor,
          surface: AppColors.backgroundColor,
          onSurface: AppColors.textColor,
        );

    return MaterialApp.router(
      title: 'CariFlow',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        scaffoldBackgroundColor: AppColors.backgroundColor,
        colorScheme: colorScheme,
        textTheme: const TextTheme(
          bodyLarge: TextStyle(color: AppColors.textColor),
          bodyMedium: TextStyle(color: AppColors.textColor),
        ),
      ),
      routerConfig: router,
    );
  }
}
