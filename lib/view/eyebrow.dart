import 'package:flutter/material.dart';

class Eyebrow extends StatefulWidget {
  const Eyebrow({super.key});

  @override
  State<Eyebrow> createState() => _EyebrowPageState();
}

class _EyebrowPageState extends State<Eyebrow> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(),

      body: Center(child: Text("Sombrancelha Page")),
    );
  }
}
