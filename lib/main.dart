import 'dart:developer';

import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tic_tac_toc_game/firebase_options.dart';
import 'package:tic_tac_toc_game/models/game_model.dart';
import 'package:tic_tac_toc_game/utils/lifecycle_handler.dart';
import 'package:tic_tac_toc_game/views/auth/auth_wrapper.dart';
import 'package:tic_tac_toc_game/views/auth/login_page.dart';
import 'package:tic_tac_toc_game/views/auth/signup_page.dart';
import 'package:tic_tac_toc_game/views/game/game_page.dart';
import 'package:tic_tac_toc_game/views/game/game_page_ai.dart';
import 'package:tic_tac_toc_game/views/home/home_page.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  FlutterError.onError = (details) {
    log(
      details.exceptionAsString(),
      error: details.exception,
      stackTrace: details.stack,
    );
  };

  PlatformDispatcher.instance.onError = (error, stackTrace) {
    log(error.toString(), error: error, stackTrace: stackTrace);
    return true;
  };

  runApp(const ProviderScope(child: MyApp()));
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return LifecycleEventHandler(
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        title: 'Tic Tac Toe',
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
          useMaterial3: true,
        ),
        home: const AuthWrapper(child: LoginPage()),
        onGenerateRoute: (settings) {
          switch (settings.name) {
            case '/login':
              return MaterialPageRoute(builder: (_) => const LoginPage());
            case '/signup':
              return MaterialPageRoute(builder: (_) => const SignupPage());
            case '/home':
              return MaterialPageRoute(builder: (_) => const HomePage());
            case '/game_ai':
              return MaterialPageRoute(builder: (_) => const GamePageAI());
            case '/game':
              final game = settings.arguments as Map<String, dynamic>;

              final gameModel = GameModel.fromMap(game);

              return MaterialPageRoute(
                builder: (_) => GamePage(game: gameModel),
              );
            default:
              return MaterialPageRoute(
                builder: (_) => const AuthWrapper(
                  child: LoginPage(),
                ),
              );
          }
        },
      ),
    );
  }
}
