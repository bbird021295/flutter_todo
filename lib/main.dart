import 'package:flutter/material.dart';
import 'package:flutter_todos/core/share_prefs.dart';
import 'package:flutter_todos/user.dart';


void main() async{

  await SharePrefsService.init();
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return new MaterialApp(
      title: 'Flutter Demo',
      theme: new ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: LoginFormWidget()
    );
  }
}