import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'shared/widgets/scaffold_with_nav.dart';
import 'features/home/home_page.dart';
import 'features/log_hike/log_hike_page.dart';
import 'features/journal/journal_page.dart';

final _rootNavigatorKey = GlobalKey<NavigatorState>(debugLabel: 'root');
final _shellNavigatorKey = GlobalKey<NavigatorState>(debugLabel: 'shell');

final router = GoRouter(
  navigatorKey: _rootNavigatorKey,
  initialLocation: '/home',
  routes: [
    ShellRoute(
      navigatorKey: _shellNavigatorKey,
      builder: (context, state, child) => ScaffoldWithNavBar(child: child),
      routes: [
        GoRoute(
          path: '/home',
          name: 'home',
          pageBuilder: (context, state) => const NoTransitionPage(
            child: HomePage(),
          ),
        ),
        GoRoute(
          path: '/log-hike',
          name: 'logHike',
          pageBuilder: (context, state) => const NoTransitionPage(
            child: LogHikePage(),
          ),
        ),
        GoRoute(
          path: '/journal',
          name: 'journal',
          pageBuilder: (context, state) => const NoTransitionPage(
            child: JournalPage(),
          ),
        ),
      ],
    ),
  ],
);

// Provider for current navigation index
final navigationIndexProvider = StateProvider<int>((ref) => 0);

// Helper to get index from path
int getIndexFromPath(String path) {
  switch (path) {
    case '/home':
      return 0;
    case '/log-hike':
      return 1;
    case '/journal':
      return 2;
    default:
      return 0;
  }
}
