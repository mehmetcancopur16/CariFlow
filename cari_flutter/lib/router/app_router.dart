import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../core/network/secure_storage_service.dart';
import '../core/network/session_state_provider.dart';
import '../features/auth/presentation/providers/auth_provider.dart';
import '../features/auth/presentation/screens/login_screen.dart';
import '../features/auth/presentation/screens/profile_screen.dart';
import '../features/auth/presentation/screens/register_screen.dart';
import '../features/clients/presentation/screens/add_client_screen.dart';
import '../features/clients/presentation/screens/client_detail_screen.dart';
import '../features/clients/presentation/screens/clients_list_screen.dart';
import '../features/settings/presentation/screens/settings_screen.dart';
import '../features/transactions/presentation/screens/quick_transaction_screen.dart';
import '../shell/app_shell.dart';

class RouterRefreshNotifier extends ChangeNotifier {
  RouterRefreshNotifier(this.ref) {
    ref.listen<AsyncValue<AuthState>>(authNotifierProvider, (_, __) {
      notifyListeners();
    });
    ref.listen<int>(sessionVersionProvider, (_, __) {
      notifyListeners();
    });
  }

  final Ref ref;
}

final appRouterProvider = Provider<GoRouter>((ref) {
  final refreshNotifier = RouterRefreshNotifier(ref);

  return GoRouter(
    initialLocation: '/',
    refreshListenable: refreshNotifier,
    routes: [
      ShellRoute(
        builder: (context, state, child) {
          return AppShell(location: state.matchedLocation, child: child);
        },
        routes: [
          GoRoute(
            path: '/',
            name: 'home',
            builder: (context, state) => const ClientsListScreen(),
          ),
          GoRoute(
            path: '/clients/new',
            name: 'add-client',
            builder: (context, state) => const AddClientScreen(),
          ),
          GoRoute(
            path: '/transaction/new',
            name: 'quick-transaction',
            builder: (context, state) => const QuickTransactionScreen(),
          ),
          GoRoute(
            path: '/profile',
            name: 'profile',
            builder: (context, state) => const ProfileScreen(),
          ),
          GoRoute(
            path: '/settings',
            name: 'settings',
            builder: (context, state) => const SettingsScreen(),
          ),
          GoRoute(
            path: '/client/:id',
            name: 'client-detail',
            builder: (context, state) {
              final id = state.pathParameters['id'] ?? '';
              return ClientDetailScreen(id: id);
            },
          ),
        ],
      ),
      GoRoute(
        path: '/login',
        name: 'login',
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: '/register',
        name: 'register',
        builder: (context, state) => const RegisterScreen(),
      ),
    ],
    redirect: (context, state) async {
      final auth = ref.read(authNotifierProvider);
      if (auth.isLoading) return null;

      final token = await ref
          .read(secureStorageServiceProvider)
          .readAccessToken();
      final hasToken = token != null && token.isNotEmpty;
      final isLoggedIn = auth.when(
        data: (state) => state.isAuthenticated,
        loading: () => false,
        error: (_, __) => false,
      );
      final isLoginRoute = state.matchedLocation == '/login';
      final isRegisterRoute = state.matchedLocation == '/register';
      final isAuthRoute = isLoginRoute || isRegisterRoute;

      if ((!hasToken || !isLoggedIn) && !isAuthRoute) {
        return '/login';
      }

      if (hasToken && isLoggedIn && isAuthRoute) {
        return '/';
      }

      return null;
    },
  );
});
