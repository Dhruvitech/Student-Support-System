import 'package:google_fonts/google_fonts.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:provider/provider.dart';
import 'package:studentsupportsystem/theme.dart';
import 'package:studentsupportsystem/firebase_options.dart';
import 'package:studentsupportsystem/providers/auth_provider.dart';
import 'package:studentsupportsystem/providers/announcement_provider.dart';
import 'package:studentsupportsystem/providers/complaint_provider.dart';
import 'package:studentsupportsystem/providers/schedule_provider.dart';
import 'package:studentsupportsystem/providers/chatbot_provider.dart';
import 'package:studentsupportsystem/providers/theme_provider.dart';
import 'package:studentsupportsystem/screens/splash/splash_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // Disable font loading from network
  GoogleFonts.config.allowRuntimeFetching = false;
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  final Future<FirebaseApp> _initialization = Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
      future: _initialization,
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return MaterialApp(
            home: Scaffold(
              body: Center(
                child: Text('Error initializing Firebase: ${snapshot.error}'),
              ),
            ),
          );
        }

        if (snapshot.connectionState == ConnectionState.done) {
          return MultiProvider(
            providers: [
              ChangeNotifierProvider(create: (_) => AuthProvider()),
              ChangeNotifierProvider(create: (_) => AnnouncementProvider()),
              ChangeNotifierProvider(create: (_) => ComplaintProvider()),
              ChangeNotifierProvider(create: (_) => ScheduleProvider()),
              ChangeNotifierProvider(create: (_) => ChatbotProvider()),
              ChangeNotifierProvider(create: (_) => ThemeProvider()),
            ],
            child: Consumer<ThemeProvider>(
              builder: (context, themeProvider, child) {
                return MaterialApp(
                  title: 'Student Support System',
                  debugShowCheckedModeBanner: false,
                  theme: lightTheme,
                  darkTheme: darkTheme,
                  themeMode: themeProvider.themeMode,
                  home: const SplashScreen(),
                );
              },
            ),
          );
        }

        return MaterialApp(
          home: Scaffold(
            body: Center(
              child: CircularProgressIndicator(),
            ),
          ),
        );
      },
    );
  }
}
