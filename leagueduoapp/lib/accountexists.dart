import 'package:flutter/material.dart';


class AccountExists extends StatelessWidget{
  @override
  Widget build(BuildContext context){
    return const Scaffold(
      body: Center(
        child: Card(
          child: Text("That account already exists"),
        ),
      ) 
    );
  }
}