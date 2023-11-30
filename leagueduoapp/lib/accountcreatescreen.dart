import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:leagueduoapp/accountfetcher.dart';
import 'package:leagueduoapp/main.dart';
import 'package:leagueduoapp/pickerscreen.dart';

class AccountCreateScreen extends StatefulWidget {
  const AccountCreateScreen({super.key, required this.userId, required this.googleSignIn});
  final String userId;
  final GoogleSignIn googleSignIn;
  @override
  State<AccountCreateScreen> createState() => _AccountCreateScreenState();
}

class _AccountCreateScreenState extends State<AccountCreateScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: FutureBuilder<List<Widget>>(
        future: getBody(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.done) {
            if (snapshot.hasError) {
              return Center(child: Text('Error: ${snapshot.error}'));
            } else {
              return Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: snapshot.data!,
              );
            }
          } else {
            return const CircularProgressIndicator(); 
          }
        },
      ),
    );
  }

  Future<List<Widget>> getBody() async {
    List<Widget> body = [];
    bool b = await checkAppAccount(widget.userId);
    if(!b){
      body.add(
        Center(
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.black, width:3),
                  shape:BoxShape.rectangle,
                  borderRadius: const BorderRadius.all(Radius.circular(5)),
                  gradient: const LinearGradient(colors: [Color.fromARGB(255, 52, 52, 52), Color.fromARGB(255, 96, 95, 95)])
                ),
                child: const Column(
                  children: [
                    Text(
                      "Hello, You Seem To Be New",
                      style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                    ),
                    Text(
                      "Please Enter Your Desired Name Below",
                      style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ),
          
              UsernameForm(userId: widget.userId),
            ]
          ),
        )
      );
      return body;
    }
    getAppAccount(widget.userId).then((AppAccount acc){
      if(acc.leagueAccount['ign'] != ""){
        Navigator.pushAndRemoveUntil<void>(
          context, 
          MaterialPageRoute<void>(builder: (BuildContext context) => PickerScreen(userId: widget.userId, googleSignIn: widget.googleSignIn)), 
          (Route<dynamic> route) => false
        ); 
      }
    }); 
    return body;
  }
}

class UsernameForm extends StatefulWidget {
  const UsernameForm({super.key, required this.userId});
  final String userId;

  @override
  _UsernameFormState createState() => _UsernameFormState();
}

class _UsernameFormState extends State<UsernameForm> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  String? _username;
  String? _IGN;

  void _submitForm() {
    if (_formKey.currentState!.validate()) {
      _formKey.currentState!.save();
    }
    getAppAccount(widget.userId, _username, _IGN).then((AppAccount acc) {
      FirebaseFirestore firestore = FirebaseFirestore.instance;
      DocumentReference documentReference =
      firestore.collection('Accounts').doc(acc.id);
      documentReference.set(acc.toMap())
      .then((_) {
        print('Document added');
      })
      .catchError((error) {
        print('Error adding document: $error');
      });
       Navigator.pushAndRemoveUntil<void>(
        context, 
        MaterialPageRoute<void>(builder: (BuildContext context) => PickerScreen(userId: widget.userId, googleSignIn: googleSignIn)), 
        (Route<dynamic> route) => false
      ); 
    });
   
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Form(
        key: _formKey,
        child: Column(
          children: [
            TextFormField(
              decoration: const InputDecoration(labelText: 'Username'),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter a username';
                }
                return null;
              },
              onSaved: (value) {
                _username = value;
              },
            ),
            const SizedBox(height: 20),
            TextFormField(
              decoration: const InputDecoration(labelText: 'IGN'),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter a IGN';
                }
                return null;
              },
              onSaved: (value) {
                _IGN = value;
              },
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _submitForm,
              style: const ButtonStyle(
                backgroundColor: MaterialStatePropertyAll<Color>(Colors.amber),
              ),
              child: const Text('Submit')
            ),
          ],
        ),
      ),
    );
  }
}
