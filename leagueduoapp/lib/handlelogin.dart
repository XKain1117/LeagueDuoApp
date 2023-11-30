import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:leagueduoapp/firebase_options.dart';
import 'main.dart';

GoogleSignInAccount? googleUser;

Future<UserCredential> signInWithGoogle() async {
  bool isFirebaseIntialized = firebaseInitialized;
  if(!isFirebaseIntialized){
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );
  }
  googleUser = await GoogleSignIn().signIn();
  final GoogleSignInAuthentication? googleAuth = await googleUser?.authentication;

  final credential = GoogleAuthProvider.credential(
    accessToken: googleAuth?.accessToken,
    idToken: googleAuth?.idToken,
  );

  UserCredential userCredential = await FirebaseAuth.instance.signInWithCredential(credential);
  return userCredential;
}

Future<void> signOutWithGoogle() async{
  FirebaseAuth.instance.signOut();
  GoogleSignIn().signOut();
  googleSignIn.disconnect();
}