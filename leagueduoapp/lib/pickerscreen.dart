import 'dart:async';
import 'dart:math';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:leagueduoapp/accountfetcher.dart';
import 'package:leagueduoapp/accountscreen.dart';
import 'package:leagueduoapp/loginscreen.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'handlelogin.dart';



class PickerScreen extends StatefulWidget {
  const PickerScreen({super.key, required this.userId, required this.googleSignIn});
  final String userId;
  final GoogleSignIn googleSignIn;
  @override
  State<PickerScreen> createState() => _PickerState();
}



class _PickerState extends State<PickerScreen>{
  late Future<AppAccount> account;
  final myController = TextEditingController();
  late Timer _timer;

   
  Future<void> refreshAccount() async {
    FirebaseFirestore firestore = FirebaseFirestore.instance;
    
    // Retrieve the username from the Firestore document
    DocumentSnapshot userSnapshot = await firestore.collection('Accounts').doc(widget.userId).get();
    String username = userSnapshot['leagueAccount']['name'];

    // Fetch updated LeagueAccount information using the stored username
    LeagueAccount updatedLeagueAccount = await fetchLeagueAccount(username);

    // Update the Firebase document with the new LeagueAccount information
    DocumentReference userDocument = firestore.collection('Accounts').doc(widget.userId);
    userDocument.update({
      'leagueAccount': updatedLeagueAccount.toMap(),
    });
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0, 
        automaticallyImplyLeading: false,
        actions: [
          Builder(
            builder: (BuildContext context) {
              return Container(
                margin: const EdgeInsets.only(top: 8.0, right: 12.0), // Adjust margins as needed
                width: 40,
                height: 40,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.green, // Change the color to your desired color
                ),
                child: IconButton(
                  icon: const Icon(Icons.menu),
                  onPressed: () {
                    Scaffold.of(context).openEndDrawer();
                  },
                  color: const Color.fromARGB(255, 250, 198, 198), // Change the color to your desired icon color
                ),
              );
            },
          ),
        ],
      ),
      endDrawer: Drawer(
        child: Padding(
          padding: EdgeInsets.only(top: MediaQuery.of(context).padding.top),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListView(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    padding: EdgeInsets.zero,
                    children: [
                      ListTile(
                        title: const Text('Logout'),
                        onTap: () {
                          signOutWithGoogle();
                          setState(() {
                            googleUser = null;
                          });
                          Navigator.pop(context);
                          Navigator.pushAndRemoveUntil<void>(
                            context,
                            MaterialPageRoute<void>(
                              builder: (BuildContext context) =>
                                  LoginScreen(googleSignIn: widget.googleSignIn),
                            ),
                            (Route<dynamic> route) => false,
                          );
                        },
                      ),
                      Divider(),
                      ListTile(
                        title: const Text('Account'),
                        onTap: () {
                          Navigator.pop(context);
                          Navigator.push<void>(
                            context,
                            MaterialPageRoute<void>(
                              builder: (BuildContext context) => AccountScreen(
                                userId: widget.userId,
                                googleSignIn: widget.googleSignIn,
                              ),
                            ),
                          );
                        },
                      ),
                      Divider(),
                      ListTile(
                        title: const Text('Refresh'),
                        onTap: () {
                          refreshAccount();
                          Navigator.pop(context); // Close the drawer after selecting an item
                        },
                      ),
                      Divider(),
                    ],
                  ),
          ],
        ),
      )
      ),
      body:Column(
        children: [
          Expanded(
            child:FutureBuilder<AppAccount>(
              future: account,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  // Loading state
                  return const Center(child:CircularProgressIndicator());
                } else if (snapshot.hasData) {
                  if(snapshot.data!.accountName != ''){
                    return Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            Dismissible(
                              key: ValueKey(snapshot.data),
                              onDismissed: (DismissDirection direction) {
                                FirebaseFirestore firestore = FirebaseFirestore.instance;
                                DocumentReference dReference = firestore.collection('Accounts').doc(widget.userId);
                                if(direction == DismissDirection.startToEnd){
                                  dReference.update({'acceptedAccounts': FieldValue.arrayUnion([snapshot.data!.toMap()])});
                                }else if(direction == DismissDirection.endToStart){
                                  dReference.update({'declinedAccounts': FieldValue.arrayUnion([snapshot.data!.toMap()])});
                                }
                                setState(() {
                                  account = chooseRandomCard();
                                });
                              },
                              child: Card(
                                margin: const EdgeInsets.all(50),
                                color: Colors.green,
                                child: Column(
                                  children: [
                                    
                                    FutureBuilder<String>(
                                      future: FirebaseStorage.instance
                                        .ref('${snapshot.data!.leagueAccount['profileIcon']}.png')
                                        .getDownloadURL(),
                                      builder: (context, urlSnapshot) {
                                        if (urlSnapshot.connectionState == ConnectionState.waiting) {
                                          return CircularProgressIndicator();
                                        } else if (urlSnapshot.hasError) {
                                          return Text('Error: ${urlSnapshot.error}');
                                        } else {
                                          // Convert the String URL to Uri
                                          Uri imageUrl = Uri.parse(urlSnapshot.data!);

                                          // Use the Uri to load the image
                                          return Container(
                                            width: 100,
                                            height: 100,
                                            decoration: BoxDecoration(
                                              image: DecorationImage(
                                                image: NetworkImage(imageUrl.toString()),
                                                fit: BoxFit.cover,
                                              ),
                                            ),
                                          );
                                        }
                                      },
                                    ),

                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        Container(
                                          width: 50,
                                          height: 50,
                                          color: Colors.amber[400],
                                          child: const SizedBox.expand(
                                            child: FittedBox(
                                              fit: BoxFit.fill,
                                              child: Icon(
                                                Icons.account_box_rounded,
                                              )
                                            )
                                          )
                                        ),
                                        const SizedBox(
                                          width: 20,
                                        ),
                                        Text(
                                          snapshot.data!.leagueAccount['name'],
                                          style: const TextStyle(
                                            fontSize: 20,
                                            backgroundColor: Color.fromARGB(255, 121, 227, 117) 
                                          ),
                                        ),
                                      ],
                                    ),
                                    Column(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        Container(
                                          width: 50,
                                          height: 50,
                                          color: const Color.fromARGB(255, 230, 20, 156),
                                          child: const SizedBox.expand(
                                            child: FittedBox(
                                              fit: BoxFit.fill,
                                              child: Icon(
                                                Icons.anchor,
                                              )
                                            )
                                          )
                                        ),
                                        const SizedBox(height:20),
                                        Row(
                                          mainAxisAlignment: MainAxisAlignment.center,
                                          children: [
                                            Text(
                                              "${snapshot.data!.leagueAccount['tier']}  ${snapshot.data!.leagueAccount['rank']}",
                                              style: const TextStyle(
                                                backgroundColor: Color.fromARGB(255, 121, 227, 117),
                                                fontSize: 20,
                                              ),     
                                            ),
                                          ],
                                        ),
                                      ],
                                    )
                                  ]
                                ),
                              )
                            )
                          ],
                      ),
                    );
                  }else{
                    return const Center(
                      child: Card(
                        margin: const EdgeInsets.all(50),
                        color: Colors.green,
                        child: Text("No More Accounts"),
                      ),
                    );
                  }
                } else if (snapshot.hasError) {
                  return Text('${snapshot.error}');
                }
                // By default, show a loading spinner.
                return const CircularProgressIndicator();
              },
            ),
          )
          
        ]
      ),
    );
    
  }

  // Future<void> createDummyAccount() async {
  //   FirebaseFirestore firestore = FirebaseFirestore.instance;
    
  //   DocumentReference documentReference = firestore.collection('Accounts').doc("juhnnie");
  //   AppAccount acc = AppAccount(accountName: "Juhnnie", leagueAccount: await fetchLeagueAccount("Juhnnie"));
  //   Map<String, dynamic> mapAcc = acc.toMap();
  //   documentReference.set(mapAcc);

  //   documentReference = firestore.collection('Accounts').doc("crbesser");
  //   acc = AppAccount(accountName: "crbesser", leagueAccount: await fetchLeagueAccount("crbesser"));
  //   mapAcc = acc.toMap();
  //   documentReference.set(mapAcc);

  //   documentReference = firestore.collection('Accounts').doc("highladyxandre");
  //   acc = AppAccount(accountName: "High Lady Xandré", leagueAccount: await fetchLeagueAccount("High Lady Xandré"));
  //   mapAcc = acc.toMap();
  //   documentReference.set(mapAcc);

  //   documentReference = firestore.collection('Accounts').doc("omegathereaper");
  //   acc = AppAccount(accountName: "Omega The Reaper", leagueAccount: await fetchLeagueAccount("Omega The Reaper"));
  //   mapAcc = acc.toMap();
  //   documentReference.set(mapAcc);
  // }

Future<AppAccount> chooseRandomCard() async {
  FirebaseFirestore firestore = FirebaseFirestore.instance;
  CollectionReference collectionReference = firestore.collection('Accounts');
  DocumentReference userDocument = collectionReference.doc(widget.userId);
  DocumentSnapshot userSnapshot = await userDocument.get();

  // Fetch all accounts
  QuerySnapshot allAccountsSnapshot = await collectionReference.get();

  if (allAccountsSnapshot.docs.isNotEmpty) {
    List<String> acceptedAccountIds = (userSnapshot['acceptedAccounts'] as List<dynamic>?)
        ?.map((account) => account['id'].toString())
        ?.toList() ?? [];
    List<String> declinedAccountIds = (userSnapshot['declinedAccounts'] as List<dynamic>?)
        ?.map((account) => account['id'].toString())
        ?.toList() ?? [];

    List<String> excludedAccountIds = [...acceptedAccountIds, ...declinedAccountIds, widget.userId];

    // Filter accounts that are not in the combined list
    List<QueryDocumentSnapshot> availableAccounts = allAccountsSnapshot.docs
      .where((document) => !excludedAccountIds.contains(document['id'].toString()))
      .toList();

    if (availableAccounts.isNotEmpty) {
      int randomIndex = Random().nextInt(availableAccounts.length);
      QueryDocumentSnapshot randomDocument = availableAccounts[randomIndex];
      return Future.delayed(const Duration(seconds: 2), () {
        return AppAccount.fromMap(randomDocument.data() as Map<String, dynamic>);
      });
    }
  }

  // Return a default account if no valid account is found
  return Future.delayed(const Duration(seconds: 2), () {
        return AppAccount();
      });
}



  @override
  void initState() {
    super.initState();
    account = chooseRandomCard();
    _timer = Timer.periodic(const Duration(seconds: 30), (Timer timer) {
      setState(() {
        print("Timer went");
        account = chooseRandomCard();
      });
    });
  }
   @override
  void dispose() {
    super.dispose();
    _timer.cancel();
  }
}

