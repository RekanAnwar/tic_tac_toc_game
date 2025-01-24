import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:tic_tac_toc_game/models/online_player_model.dart';

class LifecycleEventHandler extends StatefulWidget {
  const LifecycleEventHandler({
    Key? key,
    required this.child,
  }) : super(key: key);
  final Widget child;

  @override
  State<LifecycleEventHandler> createState() => _LifecycleEventHandlerState();
}

class _LifecycleEventHandlerState extends State<LifecycleEventHandler>
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
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    try {
      await FirebaseFirestore.instance
          .collection('onlinePlayers')
          .doc(user.uid)
          .set({
        'id': user.uid,
        'email': user.email,
        'status': OnlineStatus.offline.toString(),
        'lastSeen': DateTime.now().millisecondsSinceEpoch,
      });
    } catch (e) {
      debugPrint('Error setting offline status: $e');
    }
  }

  Future<void> _setOnlineStatus() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    try {
      await FirebaseFirestore.instance
          .collection('onlinePlayers')
          .doc(user.uid)
          .set({
        'id': user.uid,
        'email': user.email,
        'status': OnlineStatus.online.toString(),
        'lastSeen': DateTime.now().millisecondsSinceEpoch,
      });
    } catch (e) {
      debugPrint('Error setting online status: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return widget.child;
  }
}
