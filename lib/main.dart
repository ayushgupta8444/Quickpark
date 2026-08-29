import 'package:flutter/material.dart';

import 'features/splash/splash_screen.dart';

void main() {
  runApp(const QuickParkApp());
}

class QuickParkApp extends StatelessWidget {
  const QuickParkApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'QuickPark',

      theme: ThemeData(
        useMaterial3: true,
        fontFamily: 'Arial',
      ),

      home: const SplashScreen(),
    );
  }
}