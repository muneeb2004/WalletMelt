import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../screens/add_expense/add_expense_screen.dart';
import '../screens/dashboard/dashboard_screen.dart';
import '../screens/history/expense_detail_screen.dart';
import '../screens/history/history_screen.dart';
import '../screens/history/receipt_viewer_screen.dart';
import '../screens/insights/insights_screen.dart';
import '../screens/onboarding/onboarding_screen.dart';
import '../screens/settings/settings_screen.dart';
import '../screens/budget/budget_screen.dart';
import '../components/navigation/app_shell.dart';
import '../state/app_state.dart';
import '../theme/wallet_melt_theme.dart';
import '../types/settings.dart';

class WalletMeltBootstrap extends StatelessWidget {
  const WalletMeltBootstrap({super.key});

  @override
  Widget build(BuildContext context) {
    return ProviderScope(
      child: ChangeNotifierProvider(
        create: (_) => AppState()..initialize(),
        child: const WalletMeltApp(),
      ),
    );
  }
}

class WalletMeltApp extends StatefulWidget {
  const WalletMeltApp({super.key});

  @override
  State<WalletMeltApp> createState() => _WalletMeltAppState();
}

class _WalletMeltAppState extends State<WalletMeltApp> {
  late final GoRouter _router;

  @override
  void initState() {
    super.initState();
    final appState = context.read<AppState>();
    _router = GoRouter(
      initialLocation: '/',
      redirect: (context, state) {
        if (appState.isLoading) return null;
        final onboarding = appState.settings.hasCompletedOnboarding;
        final isOnboarding = state.matchedLocation == '/onboarding';
        if (!onboarding && !isOnboarding) return '/onboarding';
        if (onboarding && isOnboarding) return '/';
        return null;
      },
      refreshListenable: appState,
      routes: [
        GoRoute(
            path: '/onboarding',
            builder: (context, state) => const OnboardingScreen()),
        StatefulShellRoute.indexedStack(
          builder: (context, state, navigationShell) =>
              AppShell(navigationShell: navigationShell),
          branches: [
            StatefulShellBranch(routes: [
              GoRoute(
                  path: '/',
                  builder: (context, state) => const DashboardScreen())
            ]),
            StatefulShellBranch(routes: [
              GoRoute(
                  path: '/history',
                  builder: (context, state) => const HistoryScreen())
            ]),
            StatefulShellBranch(routes: [
              GoRoute(
                  path: '/budget',
                  builder: (context, state) => const BudgetScreen())
            ]),
            StatefulShellBranch(routes: [
              GoRoute(
                  path: '/insights',
                  builder: (context, state) => const InsightsScreen())
            ]),
            StatefulShellBranch(routes: [
              GoRoute(
                  path: '/settings',
                  builder: (context, state) => const SettingsScreen())
            ]),
          ],
        ),
        GoRoute(
            path: '/expense/new',
            builder: (context, state) => const AddExpenseScreen()),
        GoRoute(
          path: '/expense/:id',
          builder: (context, state) =>
              ExpenseDetailScreen(expenseId: state.pathParameters['id']!),
        ),
        GoRoute(
          path: '/receipt/:id',
          builder: (context, state) =>
              ReceiptViewerScreen(expenseId: state.pathParameters['id']!),
        ),
        GoRoute(
          path: '/expense/:id/edit',
          builder: (context, state) =>
              AddExpenseScreen(expenseId: state.pathParameters['id']),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<AppState>().settings;
    return MaterialApp.router(
      debugShowCheckedModeBanner: false,
      title: 'WalletMelt',
      theme: WalletMeltTheme.light(),
      darkTheme: WalletMeltTheme.dark(),
      themeMode: switch (settings.themePreference) {
        ThemePreference.light => ThemeMode.light,
        ThemePreference.dark => ThemeMode.dark,
        ThemePreference.system => ThemeMode.system,
      },
      routerConfig: _router,
      scrollBehavior: const WalletMeltScrollBehavior(),
    );
  }
}

class WalletMeltScrollBehavior extends MaterialScrollBehavior {
  const WalletMeltScrollBehavior();

  @override
  Widget buildOverscrollIndicator(
      BuildContext context, Widget child, ScrollableDetails details) {
    // Under Material 3, buildOverscrollIndicator returns a StretchingOverscrollIndicator on Android.
    // By returning child directly, we completely disable the stretch overscroll indicator,
    // which resolves the dark shadow / black screen stretching artifact when scrolling lists.
    return child;
  }

  @override
  ScrollPhysics getScrollPhysics(BuildContext context) {
    // BouncingScrollPhysics provides a premium, bouncy iOS-like scrolling experience globally,
    // which matches the premium glassmorphic feel and behaves beautifully across all platforms.
    return const BouncingScrollPhysics(
      parent: AlwaysScrollableScrollPhysics(),
    );
  }
}
