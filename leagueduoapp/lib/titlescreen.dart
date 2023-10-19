import 'package:flutter/material.dart';
import 'package:leagueduoapp/pickerscreen.dart';

class Titlescreen extends StatelessWidget{
  const Titlescreen({super.key});
  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
         Scaffold(
          body: Image.asset(
            'assets/TitleScreen_Img.png',
            fit: BoxFit.cover,
            height: double.infinity,
            width: double.infinity,
          )
        ),
        Container(
          padding: const EdgeInsets.only(bottom: 30),
          height: MediaQuery.of(context).size.height,
          width: MediaQuery.of(context).size.height,
          alignment: Alignment.bottomCenter,
          child: ElevatedButton(
            style: ButtonStyle(backgroundColor: MaterialStateProperty.all(Colors.amber[400])),
            onPressed: () => {
              Navigator.pushAndRemoveUntil<void>(
                context, 
                MaterialPageRoute<void>(builder: (BuildContext context) => const PickerScreen()), 
                (Route<dynamic> route) => false
              )
            },
            child: const Text("Login"),
          ),
        ),
        
      ],
    );
  }
}
