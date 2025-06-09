// main.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'serial_provider.dart';
import 'home_page.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    // Menggunakan ChangeNotifierProvider untuk state management
    return ChangeNotifierProvider(
      create: (context) => SerialProvider(),
      child: MaterialApp(
        title: 'STM32 Cable Tester',
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
          useMaterial3: true,
          // brightness: Brightness.dark, // Menggunakan tema gelap yang menarik
          cardTheme: CardTheme(elevation: 4, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
        ),
        home: const HomePage(),
        debugShowCheckedModeBanner: false,
      ),
    );
  }
}
