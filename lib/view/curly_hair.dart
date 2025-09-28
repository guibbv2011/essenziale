import 'package:flutter/material.dart';

class CurlyHair extends StatefulWidget {
  const CurlyHair({super.key});

  @override
  State<CurlyHair> createState() => _CurlyHairPageState();
}

class _CurlyHairPageState extends State<CurlyHair> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(),

      body: Center(child: Text("Cachos Page")),
    );
  }
}
