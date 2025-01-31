import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tic_tac_toc_game/controllers/auth_async_notifier.dart';
import 'package:tic_tac_toc_game/models/user_model.dart';

class LifecycleEventHandler extends ConsumerStatefulWidget {
  const LifecycleEventHandler({
    Key? key,
    required this.child,
  }) : super(key: key);
  final Widget child;

  @override
  ConsumerState<LifecycleEventHandler> createState() =>
      _LifecycleEventHandlerState();
}

class _LifecycleEventHandlerState extends ConsumerState<LifecycleEventHandler>
    with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _setOfflineStatus();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.inactive ||
        state == AppLifecycleState.detached) {
      _setOfflineStatus();
    } else if (state == AppLifecycleState.resumed) {
      _setOnlineStatus();
    }
  }

  Future<void> _setOfflineStatus() async {
    final isLoggedIn = ref.read(authAsyncNotifierProvider.select(
      (auth) => auth.value != null,
    ));

    if (!isLoggedIn) return;

    final user = ref.read(authAsyncNotifierProvider).value!;

    try {
      await FirebaseFirestore.instance.collection('users').doc(user.id).set(
        {
          'id': user.id,
          'email': user.email,
          'status': OnlineStatus.offline.toString(),
        },
        SetOptions(merge: true),
      );
    } catch (e) {
      debugPrint('Error setting offline status: $e');
    }
  }

  Future<void> _setOnlineStatus() async {
    final isLoggedIn = ref.read(authAsyncNotifierProvider.select(
      (auth) => auth.value != null,
    ));

    if (!isLoggedIn) return;

    final user = ref.read(authAsyncNotifierProvider).value!;

    try {
      await FirebaseFirestore.instance.collection('users').doc(user.id).set(
        {
          'id': user.id,
          'email': user.email,
          'status': OnlineStatus.online.toString(),
        },
        SetOptions(merge: true),
      );
    } catch (e) {
      debugPrint('Error setting online status: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return widget.child;
  }
}
