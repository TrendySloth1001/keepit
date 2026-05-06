import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../features/auth/presentation/auth_notifier.dart';
import '../../features/auth/presentation/pages/auth_boot_page.dart';
import '../../features/auth/presentation/pages/login_page.dart';
import '../../features/auth/presentation/pages/master_setup_page.dart';
import '../../features/auth/presentation/pages/master_unlock_page.dart';
import '../../features/auth/presentation/pages/privacy_policy_consent_page.dart';
import '../../features/settings/account_page.dart';
import '../../features/settings/change_master_password_page.dart';
import '../../features/settings/export_data_page.dart';
import '../../features/settings/help_page.dart';
import '../../features/settings/privacy_settings_page.dart';
import '../../features/settings/settings_page.dart';
import '../../features/share/data/share_models.dart';
import '../../features/share/presentation/pages/shared_item_viewer.dart';
import '../../features/share/presentation/pages/shared_with_me_page.dart';
import '../../features/vault/data/vault_models.dart';
import '../../features/vault/presentation/pages/vault_file_viewer.dart';
import '../../features/vault/presentation/pages/vault_home_page.dart';
import '../../features/vault/presentation/pages/upgrade_page.dart';
import '../../features/vault/presentation/pages/vault_icon_picker_page.dart';
import '../../features/settings/about_page.dart';
import '../../features/vault/presentation/pages/vault_item_viewer.dart';
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
        case AuthStage.needsPolicyConsent:
          return loc == '/privacy-policy/consent'
              ? null
              : '/privacy-policy/consent';
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
        path: '/privacy-policy/consent',
        builder: (_, _) => const PrivacyPolicyConsentPage(),
      ),
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
      GoRoute(path: '/vault/about', builder: (_, _) => const AboutPage()),
      GoRoute(path: '/vault/account', builder: (_, _) => const AccountPage()),
      GoRoute(
        path: '/vault/account/master-password',
        builder: (_, _) => const ChangeMasterPasswordPage(),
      ),
      GoRoute(
        path: '/vault/account/privacy',
        builder: (_, _) => const PrivacySettingsPage(),
      ),
      GoRoute(
        path: '/vault/account/export',
        builder: (_, _) => const ExportDataPage(),
      ),
      GoRoute(path: '/vault/help', builder: (_, _) => const HelpPage()),
      GoRoute(
        path: '/vault/shared',
        builder: (_, _) => const SharedWithMePage(),
      ),
      GoRoute(
        path: '/vault/shared/view',
        builder: (_, state) {
          final args = state.extra! as SharedItemViewArgs;
          return SharedItemViewer(item: args.item, incoming: args.incoming);
        },
      ),
      GoRoute(
        path: '/vault/view',
        builder: (_, state) => VaultItemViewer(item: state.extra! as VaultItem),
      ),
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
      GoRoute(
        path: '/vault/icon-picker',
        builder: (_, state) =>
            VaultIconPickerPage(initial: state.extra as String?),
      ),
      GoRoute(path: '/vault/upgrade', builder: (_, _) => const UpgradePage()),
    ],
  );
}

final appRouterProvider = Provider<GoRouter>((ref) => buildAppRouter(ref));
