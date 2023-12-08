import 'package:auto_size_text/auto_size_text.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:leagueduoapp/chathandler.dart';
import 'package:leagueduoapp/chatscreen.dart';

class AccountScreen extends StatefulWidget {
  const AccountScreen({super.key, required this.userId, required this.googleSignIn});
  final GoogleSignIn googleSignIn;
  final String userId;

  @override
  State<AccountScreen> createState() => _AccountScreenState();
}

class _AccountScreenState extends State<AccountScreen> {
  late Future<DocumentSnapshot> document;

  @override
  void initState() {
    super.initState();
    document = FirebaseFirestore.instance.collection('Accounts').doc(widget.userId).get();
  }

  Future<List<DocumentSnapshot>> fetchUserChats() async {
    final QuerySnapshot chatSnapshot = await FirebaseFirestore.instance.collection('Chats')
        .where('members', arrayContains: widget.userId)
        .get();
    return chatSnapshot.docs;
  }

  Future<List<String>> getParticipantNames(List<String> participantIds) async {
    FirebaseFirestore firestore = FirebaseFirestore.instance;
    CollectionReference accountsCollection = firestore.collection('Accounts');

    List<String> participantNames = [];

    for (var id in participantIds) {
      DocumentSnapshot accountSnapshot = await accountsCollection.doc(id).get();
      if (accountSnapshot.exists) {
        var accountData = accountSnapshot.data() as Map<String, dynamic>;
        var accountName = accountData['accountName'];
        participantNames.add(accountName);
      }
    }

    return participantNames;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SizedBox(
              height: 40,
              width: 120,
              child: ElevatedButton(
                child: const Text('Interests'),
                onPressed: () {
                  showDialog(
                    context: context,
                    builder: (BuildContext context) {
                      return Dialog(
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: SizedBox(
                          width: 500,
                          child: Container(
                            padding: const EdgeInsets.all(2),
                            child: FutureBuilder<DocumentSnapshot>(
                              future: document,
                              builder: (context, snapshot) {
                                if (snapshot.connectionState == ConnectionState.waiting) {
                                  return const CircularProgressIndicator();
                                } else if (snapshot.hasError) {
                                  return Text('Error: ${snapshot.error}');
                                } else if (!snapshot.hasData || !snapshot.data!.exists) {
                                  return const Text('Document does not exist');
                                } else {
                                  List<Map<String, dynamic>> list = (snapshot.data!['acceptedAccounts'] as List<dynamic>)
                                      .map((item) => item as Map<String, dynamic>)
                                      .toList();

                                  return ListView.builder(
                                    itemCount: list.length,
                                    itemBuilder: (context, index) {
                                      return Row(
                                        children: [
                                          Expanded(
                                            child: Dismissible(
                                              key: ValueKey(list[index]),
                                              onDismissed: (DismissDirection direction) async {
                                                FirebaseFirestore firestore = FirebaseFirestore.instance;
                                                CollectionReference accountsCollection = firestore.collection('Accounts');
                                                DocumentSnapshot userDocument = await accountsCollection.doc(widget.userId).get();

                                                String accountIdToRemove = list[index]['id'];

                                                if (userDocument.exists) {
                                                  if (direction == DismissDirection.startToEnd || direction == DismissDirection.endToStart) {
                                                    list.removeWhere((account) => account['id'] == accountIdToRemove);
                                                    await accountsCollection.doc(widget.userId).update({'acceptedAccounts': list});

                                                    // Update the FutureBuilder with the modified data
                                                    setState(() {
                                                      document = FirebaseFirestore.instance.collection('Accounts').doc(widget.userId).get();
                                                    });
                                                  }
                                                }
                                              },
                                              child: Card(
                                                margin: const EdgeInsets.all(10),
                                                color: Colors.green,
                                                child: Column(
                                                  children: [
                                                    // Use the FutureBuilder to load profile pictures
                                                    FutureBuilder<String>(
                                                      future: FirebaseStorage.instance
                                                        .ref('${list[index]['leagueAccount']['profileIcon']}.png')
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
                                                                  ))),
                                                        ),
                                                        const SizedBox(
                                                          width: 20,
                                                        ),
                                                        AutoSizeText(
                                                          "${list[index]['leagueAccount']['name']}, ${list[index]['leagueAccount']['profileIcon']} ",
                                                          minFontSize: 16.0,
                                                          maxFontSize: 32.0,
                                                          style: TextStyle(),
                                                        )
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
                                                                  ))),
                                                        ),
                                                        const SizedBox(height: 20),
                                                        Row(
                                                          mainAxisAlignment: MainAxisAlignment.center,
                                                          children: [
                                                            AutoSizeText(
                                                              "${list[index]['leagueAccount']['tier']}  ${list[index]['leagueAccount']['rank']}",
                                                              minFontSize: 16.0,
                                                              maxFontSize: 32.0,
                                                              style: TextStyle(),
                                                            )
                                                          ],
                                                        ),
                                                      ],
                                                    ),
                                                    ElevatedButton(
                                                      onPressed: () async {
                                                        final userChats = await fetchUserChats();
                                                        String otherPersonAccountName = list[index]['id']; // Replace this with the correct path to the account name
                                                        try {
                                                          // Check if there's an existing chat with the other person
                                                          var existingChat = userChats.firstWhere(
                                                            (chat) => List<String>.from(chat['members']).contains(otherPersonAccountName),
                                                            orElse: () => throw StateError('Chat not found'),
                                                          );

                                                          // Chat exists, open it
                                                          Navigator.push<void>(
                                                            context,
                                                            MaterialPageRoute<void>(
                                                              builder: (BuildContext context) => ChatsScreen(chatId: existingChat.id, userId: widget.userId, googleSignIn: widget.googleSignIn),
                                                            ),
                                                          );
                                                        } catch (error) {
                                                          FirebaseFirestore firestore = FirebaseFirestore.instance;
                                                          CollectionReference accountsCollection = firestore.collection('Chats');
                                                          DocumentReference d = accountsCollection.doc(widget.userId);
                                                          DocumentSnapshot dSnap = await d.get();
                                                          Chat c = Chat(
                                                            members: [widget.userId, list[index]['id']],
                                                            messages: <Map<String, dynamic>>[],
                                                          );                                        
                                                          DocumentReference addedDocRef = await accountsCollection.add(c.toMap());
                                                        }                                       
                                                      },
                                                      child: const Text("Open Chat"),
                                                    ),
                                                
                                                  ],
                                                ),
                                              ),
                                            ),
                                          ),
                                          

                                        ],
                                      );                                     
                                    },
                                  );
                                }
                              },
                            ),
                          ),
                        ),
                      );
                    },
                  );
                },
              ),
            ),
            const SizedBox(height: 10),
            SizedBox(
              height: 40,
              width: 120,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.pop<void>(context);
                },
                child: const Text('Back'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
