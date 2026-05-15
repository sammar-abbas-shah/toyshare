import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart' as fb_auth;
import 'firebase_options.dart';
import 'core/core.dart';
import 'screens/splash_screen.dart';
import 'screens/auth/login_screen.dart';
import 'shell/main_shell.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  await ThemeManager().loadTheme();
  SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp, DeviceOrientation.portraitDown]);
  runApp(const ToyShareApp());
}

class ToyShareApp extends StatefulWidget {
  const ToyShareApp({super.key});
  @override
  State<ToyShareApp> createState() => _ToyShareAppState();
}

class _ToyShareAppState extends State<ToyShareApp> {
  @override
  void initState() {
    super.initState();
    ThemeManager().addListener(_onThemeChange);
  }

  @override
  void dispose() {
    ThemeManager().removeListener(_onThemeChange);
    super.dispose();
  }

  void _onThemeChange() => setState(() {});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'ToyShare',
      debugShowCheckedModeBanner: false,
      themeMode: ThemeManager().themeMode,
      theme: buildLightTheme(),
      darkTheme: buildDarkTheme(),
      home: const SplashScreen(),
      routes: {
        '/auth': (_) => StreamBuilder<fb_auth.User?>(
          stream: fb_auth.FirebaseAuth.instance.authStateChanges(),
          builder: (ctx, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Scaffold(
                body: Center(child: CircularProgressIndicator(color: Color(0xFF5B4FCF))),
              );
            }
            return snapshot.data == null ? const LoginScreen() : const MainShell();
          },
        ),
        '/login': (_) => const LoginScreen(),
        '/home': (_) => const MainShell(),
      },
    );
  }
}
