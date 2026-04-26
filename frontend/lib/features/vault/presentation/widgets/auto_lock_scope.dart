import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../shared/storage/settings_service.dart';
import '../../../auth/presentation/auth_notifier.dart';
import '../../../settings/settings_notifier.dart';

/// Wraps the unlocked subtree and enforces auto-lock based on user
/// settings. Idle ticks reset on user input. Going to background only
/// locks if the elapsed time exceeds the configured window — so brief
/// detours like the file picker do not log the user out.
class AutoLockScope extends ConsumerStatefulWidget {
  const AutoLockScope({super.key, required this.child});

  final Widget child;

  @override
  ConsumerState<AutoLockScope> createState() => _AutoLockScopeState();
}

class _AutoLockScopeState extends ConsumerState<AutoLockScope> {
  Timer? _idleTimer;
  DateTime? _backgroundedAt;

  @override
  void initState() {
    super.initState();
    SystemChannels.lifecycle.setMessageHandler(_onLifecycle);
    WidgetsBinding.instance.addPostFrameCallback((_) => _resetIdleTimer());
  }

  @override
  void dispose() {
    _idleTimer?.cancel();
    SystemChannels.lifecycle.setMessageHandler(null);
    super.dispose();
  }

  Duration? _autoLockDuration() =>
      ref.read(settingsProvider).autoLock.duration;

  void _resetIdleTimer() {
    _idleTimer?.cancel();
    final d = _autoLockDuration();
    if (d == null) return;
    _idleTimer = Timer(d, _lock);
  }

  Future<String?> _onLifecycle(String? message) async {
    if (message == AppLifecycleState.paused.toString()) {
      _backgroundedAt = DateTime.now();
    } else if (message == AppLifecycleState.detached.toString()) {
      _lock();
    } else if (message == AppLifecycleState.resumed.toString()) {
      final since = _backgroundedAt;
      _backgroundedAt = null;
      final maxIdle = _autoLockDuration();
      if (maxIdle != null &&
          since != null &&
          DateTime.now().difference(since) >= maxIdle) {
        _lock();
      } else {
        _resetIdleTimer();
      }
    }
    return null;
  }

  Future<void> _lock() async {
    if (!mounted) return;
    final auth = ref.read(authProvider);
    if (auth.stage == AuthStage.unlocked) {
      await ref.read(authProvider.notifier).lock();
    }
  }

  @override
  Widget build(BuildContext context) {
    // Listen so changes to auto-lock duration take effect immediately.
    ref.listen<AppSettings>(settingsProvider, (_, _) => _resetIdleTimer());
    return Listener(
      behavior: HitTestBehavior.translucent,
      onPointerDown: (_) => _resetIdleTimer(),
      onPointerMove: (_) => _resetIdleTimer(),
      onPointerSignal: (_) => _resetIdleTimer(),
      child: widget.child,
    );
  }
}
