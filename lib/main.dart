
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:next_app/routes/app_routes.dart';
import 'package:next_app/view/on_boarding/started_view.dart';

void main(List<String> args){
  runApp(MyApp());
  
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      theme: ThemeData(
          primarySwatch: Colors.purple,
      ),
      home: StartedView(),
      routes: AppRoutes.getRoutes(),

    );
  }
}
