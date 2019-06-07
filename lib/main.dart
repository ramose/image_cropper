import 'package:flutter/material.dart';
import 'package:cropper/camera1.dart';

void main() => runApp(MyApp());

class MyApp extends StatelessWidget {
  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Image Cropper',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: Camera1Page(),
    );
  }
}
