import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../core/constants/app_colors.dart';
import '../features/auth/presentation/providers/auth_provider.dart';

/// Main app chrome: persistent sidebar on wide layouts, bottom navigation on narrow.
class AppShell extends ConsumerWidget {
  const AppShell({required this.child, required this.location, super.key});

  final Widget child;
  final String location;

  static const _paths = <String>[
    '/',
    '/clients',
    '/clients/new',
    '/transaction/new',
    '/profile',
    '/settings',
  ];

  static int selectedIndexForLocation(String loc) {
    if (loc.startsWith('/client/')) return 1;
    final idx = _paths.indexOf(loc);
    return idx >= 0 ? idx : 0;
  }

  void _go(BuildContext context, int index) {
    if (index >= 0 && index < _paths.length) {
      context.go(_paths[index]);
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedIndex = selectedIndexForLocation(location);
    final width = MediaQuery.sizeOf(context).width;
    final useRail = width >= 900;
    final extendedRail = width >= 1280;

    Future<void> logout() async {
      await ref.read(authNotifierProvider.notifier).logout();
    }

    final destinations = <NavigationRailDestination>[
      const NavigationRailDestination(
        icon: Icon(Icons.space_dashboard_outlined),
        selectedIcon: Icon(Icons.space_dashboard_rounded),
        label: Text('Dashboard'),
      ),
      const NavigationRailDestination(
        icon: Icon(Icons.groups_outlined),
        selectedIcon: Icon(Icons.groups_rounded),
        label: Text('Musteriler'),
      ),
      const NavigationRailDestination(
        icon: Icon(Icons.person_add_alt_outlined),
        selectedIcon: Icon(Icons.person_add_alt_1_rounded),
        label: Text('Yeni'),
      ),
      const NavigationRailDestination(
        icon: Icon(Icons.payments_outlined),
        selectedIcon: Icon(Icons.payments_rounded),
        label: Text('Islem'),
      ),
      const NavigationRailDestination(
        icon: Icon(Icons.person_outline_rounded),
        selectedIcon: Icon(Icons.person_rounded),
        label: Text('Profil'),
      ),
      const NavigationRailDestination(
        icon: Icon(Icons.settings_outlined),
        selectedIcon: Icon(Icons.settings_rounded),
        label: Text('Ayarlar'),
      ),
    ];

    final navBarDestinations = <NavigationDestination>[
      const NavigationDestination(
        icon: Icon(Icons.space_dashboard_outlined),
        selectedIcon: Icon(Icons.space_dashboard_rounded),
        label: 'Ana',
      ),
      const NavigationDestination(
        icon: Icon(Icons.groups_outlined),
        selectedIcon: Icon(Icons.groups_rounded),
        label: 'Liste',
      ),
      const NavigationDestination(
        icon: Icon(Icons.person_add_alt_outlined),
        selectedIcon: Icon(Icons.person_add_alt_1_rounded),
        label: 'Ekle',
      ),
      const NavigationDestination(
        icon: Icon(Icons.payments_outlined),
        selectedIcon: Icon(Icons.payments_rounded),
        label: 'Islem',
      ),
      const NavigationDestination(
        icon: Icon(Icons.person_outline_rounded),
        selectedIcon: Icon(Icons.person_rounded),
        label: 'Profil',
      ),
      const NavigationDestination(
        icon: Icon(Icons.settings_outlined),
        selectedIcon: Icon(Icons.settings_rounded),
        label: 'Ayar',
      ),
    ];

    Widget leadingHeader({required bool compact}) {
      return Padding(
        padding: EdgeInsets.fromLTRB(
          compact ? 12 : 16,
          compact ? 16 : 20,
          12,
          8,
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    AppColors.primaryColor,
                    AppColors.primaryColor.withAlpha(200),
                  ],
                ),
                borderRadius: BorderRadius.circular(14),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primaryColor.withAlpha(80),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: const Icon(
                Icons.account_balance_wallet_rounded,
                color: Colors.white,
                size: 22,
              ),
            ),
            if (!compact) ...[
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'CariFlow',
                      style: TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 18,
                        color: AppColors.textColor,
                      ),
                    ),
                    Text(
                      'Cari takip',
                      style: TextStyle(
                        fontSize: 12,
                        color: AppColors.textColor.withAlpha(140),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      );
    }

    if (useRail) {
      return Scaffold(
        body: Row(
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 280),
              curve: Curves.easeOutCubic,
              width: extendedRail ? 268 : 88,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    AppColors.primaryColor.withAlpha(22),
                    Colors.white,
                    AppColors.successColor.withAlpha(16),
                  ],
                ),
                border: Border(
                  right: BorderSide(
                    color: AppColors.primaryColor.withAlpha(35),
                  ),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  leadingHeader(compact: !extendedRail),
                  Expanded(
                    child: NavigationRail(
                      extended: extendedRail,
                      backgroundColor: Colors.transparent,
                      selectedIndex: selectedIndex,
                      onDestinationSelected: (i) => _go(context, i),
                      labelType: extendedRail
                          ? NavigationRailLabelType.all
                          : NavigationRailLabelType.none,
                      indicatorColor: AppColors.primaryColor.withAlpha(40),
                      selectedIconTheme: const IconThemeData(
                        color: AppColors.primaryColor,
                      ),
                      unselectedIconTheme: IconThemeData(
                        color: AppColors.textColor.withAlpha(160),
                      ),
                      destinations: destinations,
                    ),
                  ),
                  const Divider(height: 1),
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      vertical: 12,
                      horizontal: 8,
                    ),
                    child: extendedRail
                        ? ListTile(
                            leading: const Icon(Icons.logout_rounded),
                            title: const Text('Cikis Yap'),
                            onTap: logout,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          )
                        : IconButton(
                            tooltip: 'Cikis Yap',
                            onPressed: logout,
                            icon: const Icon(Icons.logout_rounded),
                          ),
                  ),
                ],
              ),
            ),
            Expanded(child: child),
          ],
        ),
      );
    }

    return Scaffold(
      body: child,
      bottomNavigationBar: NavigationBar(
        selectedIndex: selectedIndex,
        onDestinationSelected: (i) => _go(context, i),
        height: 72,
        indicatorColor: AppColors.primaryColor.withAlpha(45),
        destinations: navBarDestinations,
      ),
    );
  }
}
