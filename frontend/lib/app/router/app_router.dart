import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../features/auth/presentation/auth_notifier.dart';
import '../../features/auth/presentation/pages/auth_boot_page.dart';
import '../../features/auth/presentation/pages/login_page.dart';
import '../../features/auth/presentation/pages/master_setup_page.dart';
import '../../features/auth/presentation/pages/master_unlock_page.dart';
import '../../features/settings/settings_page.dart';
import '../../features/vault/data/vault_models.dart';
import '../../features/vault/presentation/pages/vault_file_viewer.dart';
import '../../features/vault/presentation/pages/vault_home_page.dart';
import '../../features/vault/presentation/pages/vault_key_editor.dart';
import '../../features/vault/presentation/pages/vault_note_editor.dart';
import '../../features/vault/presentation/pages/vault_password_editor.dart';
import '../../features/vault/presentation/pages/vault_uploader_page.dart';

class _AuthListenable extends ChangeNotifier {
  _AuthListenable(Ref ref) {
    ref.listen<AuthState>(authProvider, (_, _) => notifyListeners());
  }
}

GoRouter buildAppRouter(Ref ref) {
  final listenable = _AuthListenable(ref);

  return GoRouter(
    refreshListenable: listenable,
    initialLocation: '/boot',
    redirect: (context, state) {
      final auth = ref.read(authProvider);
      final loc = state.matchedLocation;
      switch (auth.stage) {
        case AuthStage.initializing:
          return loc == '/boot' ? null : '/boot';
        case AuthStage.signedOut:
          return loc == '/login' ? null : '/login';
        case AuthStage.needsMasterSetup:
          return loc == '/master/setup' ? null : '/master/setup';
        case AuthStage.locked:
          return loc == '/master/unlock' ? null : '/master/unlock';
        case AuthStage.unlocked:
          if (loc == '/boot' ||
              loc == '/login' ||
              loc == '/master/setup' ||
              loc == '/master/unlock') {
            return '/vault';
          }
          return null;
      }
    },
    routes: [
      GoRoute(path: '/boot', builder: (_, _) => const AuthBootPage()),
      GoRoute(path: '/login', builder: (_, _) => const LoginPage()),
      GoRoute(
        path: '/master/setup',
        builder: (_, _) => const MasterSetupPage(),
      ),
      GoRoute(
        path: '/master/unlock',
        builder: (_, _) => const MasterUnlockPage(),
      ),
      GoRoute(path: '/vault', builder: (_, _) => const VaultHomePage()),
      GoRoute(path: '/vault/settings', builder: (_, _) => const SettingsPage()),
      GoRoute(
        path: '/vault/edit/password',
        builder: (_, state) =>
            VaultPasswordEditor(existing: state.extra as VaultItem?),
      ),
      GoRoute(
        path: '/vault/edit/note',
        builder: (_, state) =>
            VaultNoteEditor(existing: state.extra as VaultItem?),
      ),
      GoRoute(
        path: '/vault/edit/key',
        builder: (_, state) =>
            VaultKeyEditor(existing: state.extra as VaultItem?),
      ),
      GoRoute(
        path: '/vault/upload/file',
        builder: (_, _) => const VaultUploaderPage(type: VaultItemType.file),
      ),
      GoRoute(
        path: '/vault/upload/image',
        builder: (_, _) => const VaultUploaderPage(type: VaultItemType.image),
      ),
      GoRoute(
        path: '/vault/file',
        builder: (_, state) => VaultFileViewer(item: state.extra! as VaultItem),
      ),
    ],
  );
}

final appRouterProvider = Provider<GoRouter>((ref) => buildAppRouter(ref));
