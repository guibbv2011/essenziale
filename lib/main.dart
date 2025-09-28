import 'package:essenziale/view/curly_hair.dart';
import 'package:essenziale/view/eyebrow.dart';
import 'package:essenziale/view/home.dart';
import 'package:essenziale/view/manicure.dart';
import 'package:essenziale/view/massage.dart';
import 'package:essenziale/view/straight_hair.dart';
import 'package:flutter/material.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    const String title = 'Essenziale';
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: title,
      initialRoute: '/',
      routes: {
        '/': (context) => const MyHomePage(title: title),
        '/curly': (context) => const CurlyHair(),
        '/straight': (context) => const StraightHair(),
        '/manicure': (context) => const Manicure(),
        '/massage': (context) => const Massage(),
        '/eyebrow': (context) => const Eyebrow(),
      },
      theme: ThemeData(
        // test of englush spell
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
      ),
    );
  }
}
