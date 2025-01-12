import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tic_tac_toc_game/firebase_options.dart';
import 'package:tic_tac_toc_game/views/auth/auth_wrapper.dart';
import 'package:tic_tac_toc_game/views/auth/login_page.dart';
import 'package:tic_tac_toc_game/views/auth/signup_page.dart';
import 'package:tic_tac_toc_game/views/game/game_page.dart';
import 'package:tic_tac_toc_game/views/home/home_page.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  runApp(const ProviderScope(child: MyApp()));
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Tic Tac Toe',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: const AuthWrapper(),
      routes: {
        '/login': (context) => const LoginPage(),
        '/signup': (context) => const SignupPage(),
        '/home': (context) => const HomePage(),
        '/game': (context) => const GamePage(),
      },
    );
  }
}
