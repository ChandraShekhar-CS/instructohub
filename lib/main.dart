import 'package:flutter/material.dart';
import 'login_screen.dart';
import 'dashboard_screen.dart';

// The main function is the entry point for all Flutter apps.
void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      // The title of the application.
      title: 'InstructoHub',
      // Hides the debug banner in the top-right corner.
      debugShowCheckedModeBanner: false,
      // Defines the theme for the application.
      theme: ThemeData(
        primarySwatch: Colors.blue,
        // Sets the default font for the app.
        fontFamily: 'Inter',
        // Defines the visual properties of the app bar.
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.white,
          elevation: 0,
          iconTheme: IconThemeData(color: Colors.black),
          titleTextStyle: TextStyle(color: Colors.black, fontSize: 18, fontWeight: FontWeight.bold),
        ),
      ),
      // The initial screen to be displayed when the app starts.
      home: const LoginScreen(),
      // Defines the named routes for navigation.
      // The '/dashboard' route is removed because we navigate to it
      // using MaterialPageRoute to pass the required 'token' argument from the login screen.
      routes: {
        '/login': (context) => const LoginScreen(),
      },
    );
  }
}
