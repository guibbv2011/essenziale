import 'package:flutter/material.dart';

class Massage extends StatefulWidget {
  const Massage({super.key});

  @override
  State<Massage> createState() => _MassagePageState();
}

class _MassagePageState extends State<Massage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(),
      body: Center(child: Text("LisoPage")),
    );
  }
}
