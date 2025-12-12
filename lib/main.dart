import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'firebase_options.dart';
import 'services/auth_service.dart';
import 'providers/auth_provider.dart';
import 'providers/settings_provider.dart';
import 'providers/user_provider.dart';

import 'utils/theme.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_quill/flutter_quill.dart';
import 'package:campusdrive/screens/splash_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  debugPrint('Starting App Initialization...');

  try {
    if (Firebase.apps.isEmpty) {
      debugPrint('Initializing Firebase...');
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );
      debugPrint('Firebase Initialized.');
    } else {
      debugPrint('Firebase already initialized.');
    }
  } catch (e) {
    debugPrint('Firebase Initialization Error: $e');
  }

  try {
    debugPrint('Initializing Supabase...');
    // Initialize Supabase
    await Supabase.initialize(
      url: 'https://qcddivpbaebrzqhhvqzw.supabase.co', // Supabase dashboard
      anonKey:
          'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InFjZGRpdnBiYWVicnpxaGh2cXp3Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3NjQyMzk2OTEsImV4cCI6MjA3OTgxNTY5MX0.-UUoluRuhK2uazem9c_X2ERO-xrSiqLxwg8v_e9iCGU', // anon public key
    );
    debugPrint('Supabase Initialized.');
  } catch (e) {
    debugPrint('Supabase Initialization Error: $e');
  }

  final authService = AuthService();
  try {
    debugPrint('Initializing AuthService...');
    await AuthService.initialize(); // Static init for Google Sign In
    debugPrint('AuthService Initialized.');
  } catch (e) {
    debugPrint('AuthService Initialization Error: $e');
  }

  final authProvider = AuthProvider(authService);

  // FPS Logger
  if (const bool.fromEnvironment('dart.vm.product') == false) {
    var frameCount = 0;
    var lastTime = DateTime.now();
    WidgetsBinding.instance.addTimingsCallback((timings) {
      frameCount += timings.length;
      final now = DateTime.now();
      if (now.difference(lastTime).inSeconds >= 2) {
        final fps = frameCount / now.difference(lastTime).inSeconds;
        debugPrint('Avg FPS: ${fps.toStringAsFixed(1)}');
        frameCount = 0;
        lastTime = now;
      }
    });
  }

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => authProvider),
        ChangeNotifierProvider(create: (_) => SettingsProvider()),
        ChangeNotifierProvider(create: (_) => UserProvider()),
      ],
      child: const CampusDriveApp(),
    ),
  );
}

class CampusDriveApp extends StatelessWidget {
  const CampusDriveApp({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<SettingsProvider>(
      builder: (context, settings, _) {
        return MaterialApp(
          title: 'CampusDrive',
          debugShowCheckedModeBanner: false,
          theme: ThemeData(
            primaryColor: const Color(0xFF7C3AED),
            scaffoldBackgroundColor: const Color(0xFFF7F5FF),
            useMaterial3: true,
            colorScheme: ColorScheme.fromSeed(
              seedColor: const Color(0xFF7C3AED),
              primary: const Color(0xFF7C3AED),
              surface: const Color(0xFFF7F5FF),
            ),
            appBarTheme: const AppBarTheme(
              backgroundColor: Color(0xFFF7F5FF),
              surfaceTintColor: Colors.transparent,
              elevation: 0,
              titleTextStyle: TextStyle(
                color: Colors.black,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
              iconTheme: IconThemeData(color: Colors.black),
            ),
            cardTheme: CardThemeData(
              color: Colors.white,
              elevation: 0,
              margin: EdgeInsets.zero,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
          ),
          darkTheme: AppTheme.darkTheme,
          themeMode: settings.themeMode,
          showPerformanceOverlay: settings.showPerformanceOverlay,
          localizationsDelegates: [
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
            // FlutterQuillLocalizations.delegate is likely not needed if the package handles it internally
            // or if it's not exported. Checking docs, typically it is:
            // FlutterQuillLocalizations.delegate,
            // If it's failing, we can try omitting it or using a standard delegate if available.
            // For now, let's keep standard delegates. If issues persist, we will investigate FlutterQuill specific reqs.
            // Actually, recent versions might have changed this.
            // Let's try to add it back if it resolves, but since the previous error said 'Undefined',
            // and we imported 'flutter_quill.dart', maybe it is FlutterQuillLocalizations.delegate but from a specific package?
            // The user installed flutter_localizations.
            // Let's rely on standard localizations first. If the error "FlutterQuillLocalizations instance is required" appears again,
            // we will need to find the correct import.
            // However, the error screen explicitly asked for `FlutterQuillLocalizations.delegate`.
            // Let's assume it IS in flutter_quill but maybe under a different name or path?
            // Wait, `flutter_quill` 10+ might have split it?
            // In 10.x+ it is usually `FlutterQuillLocalizations.delegate` but needs `flutter_localizations` setup.
            // Let's try adding `FlutterQuillLocalizations.delegate` again but ensure `flutter_quill.dart` is imported.
            FlutterQuillLocalizations.delegate,
          ],
          supportedLocales: const [
            Locale('en', 'US'),
            Locale('es', 'ES'),
            Locale('fr', 'FR'),
            Locale('zh', 'CN'),
            Locale('ja', 'JP'),
            // Add other locales as needed
          ],
          home: const SplashScreen(),
        );
      },
    );
  }
}
