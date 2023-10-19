import 'package:flutter/material.dart';
import 'package:leagueduoapp/titlescreen.dart';

void main() => runApp(LeagueDuoApp());



class LeagueDuoApp extends StatelessWidget {
  const LeagueDuoApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
          home: Titlescreen(),
    );
  }
}

