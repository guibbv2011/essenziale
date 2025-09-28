import 'package:flutter/material.dart';

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        toolbarHeight: 72,
        titleTextStyle: TextStyle(
          fontSize: 48,
          color: Colors.grey.shade800,
          fontStyle: .italic,
          fontFamily: 'papyrus',
        ),
        centerTitle: true,
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: Text(widget.title),
      ),
      body: Expanded(
        child: Center(
          child: ListView(
            padding: .all(12),
            children: [
              // TODO :
              // Display Lottie Persons that are clickable
              // To your page randomically...
              _container(context, "curly"),
              _container(context, "straight"),
              _container(context, "manicure"),
              _container(context, "eyebrow"),
              _container(context, "massage"),
            ],
          ),
        ),
      ),
    );
  }
}

Widget _container(BuildContext context, String name) {
  double hcard = MediaQuery.of(context).size.height * .88;
  double wcard = MediaQuery.of(context).size.width * 0.75;

  return Padding(
    padding: const EdgeInsets.all(8.0),
    child: Container(
      decoration: BoxDecoration(border: .all(), borderRadius: .circular(16)),
      height: hcard,
      width: wcard,
      child: ElevatedButton(
        onPressed: () => Navigator.pushNamed(context, '/$name'),
        child: Text('${name[0].toUpperCase()}${name.substring(1)}'),
      ),
      // Lottie with animation of each person
      // child: Center(child: Text(name, style: TextStyle(fontSize: 22))),
    ),
  );
}
