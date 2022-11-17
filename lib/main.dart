import 'dart:ffi';
import 'dart:io';
import 'package:path/path.dart' as path;
import 'package:flutter/material.dart';
import 'package:flutter_demo/my_random.dart';
import 'dart:math';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: const MyHomePage(title: 'Flutter Demo Home Page'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({Key? key, required this.title}) : super(key: key);

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  int _displayValue = 0;
  late MyRandom _randomGenerator;
  double _sliderValue = 10.0 / 31.0;

  @override
  void initState() {
    super.initState();
    late DynamicLibrary dl;
    if (Platform.isAndroid) {
      dl = DynamicLibrary.open('libmy_random.so');
    } else if (Platform.isWindows) {
      dl = DynamicLibrary.open(path.join('my_random.dll'));
    }
    _randomGenerator = MyRandom(dl);
  }

  void _newRandom() {
    setState(() {
      _displayValue =
          _randomGenerator.myRandom(pow(2, _sliderValue * 31 + 1).ceil());
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Slider(
              value: _sliderValue,
              divisions: 31,
              onChanged: (value) {
                setState(() {
                  _sliderValue = value;
                });
              },
            ),
            Text(
              'Max Random: ${pow(2, _sliderValue * 31 + 1).ceil()}',
            ),
            Text(
              '$_displayValue',
              style: Theme.of(context).textTheme.headline4,
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _newRandom,
        tooltip: 'Increment',
        child: const Icon(Icons.casino),
      ),
    );
  }
}
