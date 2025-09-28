import 'package:flutter/material.dart';

class Manicure extends StatefulWidget {
  const Manicure({super.key});

  @override
  State<Manicure> createState() => _ManicurePageState();
}

class _ManicurePageState extends State<Manicure> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(),
      body: Center(child: Text("Manicure Page")),
    );
  }
}
