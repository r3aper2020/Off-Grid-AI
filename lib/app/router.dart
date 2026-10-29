import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../core/database/app_database.dart';
import '../features/chat/presentation/chat_home_screen.dart';
import '../features/chat/presentation/conversation_screen.dart';
import '../features/chat/presentation/history_screen.dart';
import '../features/library/presentation/library_screen.dart';
import '../features/models/presentation/models_screen.dart';
import '../features/settings/presentation/settings_screen.dart';
import '../features/tools/presentation/navigation_screen.dart';
import '../features/tools/presentation/tools_screen.dart';
import 'shell.dart';

final _rootKey = GlobalKey<NavigatorState>();

GoRouter buildRouter() => GoRouter(
  navigatorKey: _rootKey,
  initialLocation: '/chat',
  routes: [
    StatefulShellRoute.indexedStack(
      builder: (context, state, shell) => AppShell(shell: shell),
      branches: [
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/chat',
              builder: (_, _) => const ChatHomeScreen(),
              routes: [
                // Full-screen so the composer isn't stacked on the nav bar.
                GoRoute(
                  path: 'c/:id',
                  parentNavigatorKey: _rootKey,
                  builder: (_, state) => ConversationScreen(
                    conversationId: int.parse(state.pathParameters['id']!),
                  ),
                ),
                GoRoute(
                  path: 'history',
                  parentNavigatorKey: _rootKey,
                  builder: (_, _) => const HistoryScreen(),
                ),
              ],
            ),
          ],
        ),
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/library',
              builder: (_, state) => LibraryScreen(
                category: _category(state.uri.queryParameters['category']),
              ),
            ),
          ],
        ),
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/tools',
              builder: (_, _) => const ToolsScreen(),
              routes: [
                GoRoute(
                  path: 'navigation',
                  builder: (_, _) => const NavigationScreen(),
                ),
              ],
            ),
          ],
        ),
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/settings',
              builder: (_, _) => const SettingsScreen(),
              routes: [
                GoRoute(
                  path: 'models',
                  parentNavigatorKey: _rootKey,
                  builder: (_, _) => const ModelsScreen(),
                ),
              ],
            ),
          ],
        ),
      ],
    ),
  ],
);

PackCategory? _category(String? name) =>
    PackCategory.values.where((c) => c.name == name).firstOrNull;
