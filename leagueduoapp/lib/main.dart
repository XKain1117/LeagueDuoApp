import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:image_picker/image_picker.dart';
import 'package:leagueduoapp/firebase_options.dart';
import 'package:leagueduoapp/titlescreen.dart';


bool _initialized = false;

GoogleSignIn googleSignIn = GoogleSignIn(
  scopes: [
    'email',
  ],
);

Future<void> main() async{
  WidgetsFlutterBinding.ensureInitialized();
  try{
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    _initialized = true;
  }catch(e){
    print("Didnt initialize");
    _initialized = false;
  }
  

  runApp(MaterialApp(
    theme: ThemeData(scaffoldBackgroundColor: const Color.fromARGB(255, 33, 100, 35)),
    home: Titlescreen(googleSignIn: googleSignIn,),
  ));
}

bool get firebaseInitialized => _initialized;

class LeagueDuoApp extends StatelessWidget {
  const LeagueDuoApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
          home: Titlescreen(googleSignIn: googleSignIn,),
    );
  }
}

