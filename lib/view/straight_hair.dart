import 'package:flutter/material.dart';

class StraightHair extends StatefulWidget {
  const StraightHair({super.key});

  @override
  State<StraightHair> createState() => _StraightHairPageState();
}

class _StraightHairPageState extends State<StraightHair> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(),
      body: Center(child: Text("Liso Page")),
    );
  }
}
