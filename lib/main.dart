import 'package:flutter/material.dart';
import 'package:weather_app/homescreen.dart';

//import 'package:geolocator_app/reverse_Geocoding.dart';



void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Flutter Demo',
      home: Loading(),
    );
  }
}
