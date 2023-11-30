import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_signin_button/button_list.dart';
import 'package:flutter_signin_button/button_view.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:leagueduoapp/accountcreatescreen.dart';
import 'main.dart';
import 'handlelogin.dart';



class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key, required this.googleSignIn});
  final GoogleSignIn googleSignIn;

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SignInButton(
              Buttons.GoogleDark,
              onPressed: () {
                signInWithGoogle().then((UserCredential cred) {
                  setState(() {
                  
                  });
                  Navigator.pushAndRemoveUntil<void>(
                    context, 
                    MaterialPageRoute<void>(builder: (BuildContext context) => AccountCreateScreen(userId: cred.user!.uid, googleSignIn: googleSignIn)), 
                    (Route<dynamic> route) => false
                  ); 
                });
                
              },
            )
          ],
        ),
      )
    );
  }
}