import 'package:flutter/material.dart';
import 'screens/login_screen.dart';
import 'screens/signup_screen.dart';
import 'screens/home_screen.dart';
import 'screens/capture_news_screen.dart';
import 'package:hive/hive.dart';
import 'package:hive_flutter/hive_flutter.dart';

// import 'screens/profile_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Hive.initFlutter();
  await Hive.openBox('newsBox');
  runApp(const MyApp());
}class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Crowdsourcing News App',
      theme: ThemeData(
        // Define the default brightness and background color
        brightness: Brightness.light,
        primaryColor: Colors.blueGrey[800], // Dark, neutral for professionalism
        colorScheme: ColorScheme.fromSwatch().copyWith(
          secondary:
              Colors.orange[600], // Accent color for urgency and highlights
        ),

        // AppBar styling
        appBarTheme: AppBarTheme(
          color: Colors.blueGrey[800],
          iconTheme: const IconThemeData(color: Colors.white),
          titleTextStyle: const TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),

        // Text styling
        textTheme: TextTheme(
          headlineLarge: TextStyle(
              fontSize: 32.0,
              fontWeight: FontWeight.bold,
              color: Colors.blueGrey[800]),
          headlineSmall: TextStyle(
              fontSize: 20.0,
              fontWeight: FontWeight.bold,
              color: Colors.blueGrey[800]),
          bodyMedium: TextStyle(fontSize: 16.0, color: Colors.grey[800]),
        ),

        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.orange[600], // Background color
            foregroundColor: Colors.white, // Text color
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            textStyle:
                const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        ), // Input decoration for text fields
        inputDecorationTheme: InputDecorationTheme(
          border: const OutlineInputBorder(),
          focusedBorder: OutlineInputBorder(
            borderSide: BorderSide(color: Colors.orange[600]!, width: 2),
          ),
          enabledBorder: OutlineInputBorder(
            borderSide: BorderSide(color: Colors.blueGrey[400]!, width: 1),
          ),
          labelStyle: TextStyle(color: Colors.blueGrey[800]),
        ),

        // Icon themes
        iconTheme: IconThemeData(
          color: Colors.blueGrey[800],
        ),
      ),
      initialRoute: '/login',
      routes: {
        '/login': (context) => const LoginScreen(),

        '/signup': (context) => const SignupScreen(),
        '/home': (context) => const HomeScreen(),
        '/capture_news': (context) => const CaptureNewsScreen(),
        // '/profile': (context) => ProfileScreen(),
      },
    );
  }
}
