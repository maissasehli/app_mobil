// ...existing code...
import 'package:airbus_app/screen/home_screen.dart';
import 'package:airbus_app/screen/docs_screen.dart';
import 'package:airbus_app/screen/extnot_screen.dart';
import 'package:airbus_app/screen/login_screen.dart';
import 'package:flutter/material.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Airbus App',
      initialRoute: '/login',
      routes: {
        '/login': (context) => LoginScreen(),
        '/home': (context) => HomeScreen(),
        '/docs': (context) => DocsScreen(),
        '/extnot': (context) => ExtnotScreen(),
      },
      // ...existing code...
    );
  }
}
// ...existing code...