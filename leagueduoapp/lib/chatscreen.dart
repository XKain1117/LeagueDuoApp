import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_signin_button/button_list.dart';
import 'package:flutter_signin_button/button_view.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:leagueduoapp/accountcreatescreen.dart';
import 'package:leagueduoapp/chathandler.dart';
import 'main.dart';
import 'handlelogin.dart';

class ChatsScreen extends StatefulWidget {
  const ChatsScreen({super.key,required this.chatId, required this.userId, required this.googleSignIn});
  final GoogleSignIn googleSignIn;
  final String userId;
  final String chatId;

  @override
  State<ChatsScreen> createState() => _ChatsScreenState();
}

class _ChatsScreenState extends State<ChatsScreen> {
  final TextEditingController _messageController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: FutureBuilder<String>(
          future: getChatName(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return Text('Loading...'); // or any other loading indicator
            } else if (snapshot.hasError) {
              return Text('Error: ${snapshot.error}');
            } else {
              final chatName = snapshot.data;
              return Text(chatName != null ? chatName : 'Chat Name');
            }
          },
        )
      ),
      body: Column(
        children: [
          Expanded(
            child: StreamBuilder<DocumentSnapshot>(
              stream: FirebaseFirestore.instance.collection('Chats').doc(widget.chatId).snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const CircularProgressIndicator();
                } else if (snapshot.hasError) {
                  return Text('Error: ${snapshot.error}');
                } else if (!snapshot.hasData || !snapshot.data!.exists) {
                  return const Text('Chat does not exist');
                } else {
                  var chatData = snapshot.data!.data() as Map<String, dynamic>;
                  var chat = Chat.fromMap(chatData);
                  var messages = chat.messages;

                  return ListView.builder(
                    itemCount: messages.length,
                    itemBuilder: (context, index) {
                      var message = messages[index];
                      var senderName = message['senderName'] as String;
                      var contents = message['contents'] as String;
                      var timestamp = message['timestamp'] as Timestamp;

                      return MessageWidget(senderName: senderName, contents: contents, timestamp: timestamp);
                    },
                  );
                }
              },
            ),
          ),
          _buildMessageInput(),
        ],
      ),
    );
  }

  Widget _buildMessageInput() {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _messageController,
              decoration: InputDecoration(
                hintText: 'Type your message...',
              ),
            ),
          ),
          IconButton(
            icon: Icon(Icons.send),
            onPressed: () {
              _sendMessage();
            },
          ),
        ],
      ),
    );
  }

  Future<String> getChatName() async{
    FirebaseFirestore firestore = FirebaseFirestore.instance;
    DocumentReference chat = firestore.collection('Chats').doc(widget.chatId);
    DocumentSnapshot chatSnap = await chat.get();
    List<String> chatMembers = List<String>.from(chatSnap['members'] ?? []);    
    for(var member in chatMembers){
      DocumentReference acc = firestore.collection('Accounts').doc(member);
      DocumentSnapshot accSnap = await acc.get();
      if(accSnap['id'] != widget.userId){
        String chatName = accSnap['accountName'];
        return chatName;
      }
    }
    return "";
  }

  void _sendMessage() async {
    FirebaseFirestore firestore = FirebaseFirestore.instance;
    CollectionReference accountsCollection = firestore.collection('Accounts');
    DocumentSnapshot userDocument = await accountsCollection.doc(widget.userId).get();
    String messageText = _messageController.text.trim();
    if (messageText.isNotEmpty) {
      // Create a map with the message data
      Map<String, dynamic> messageData = {
        'contents': messageText,
        'senderId': widget.userId,
        'senderName': userDocument['accountName'],
        'timestamp': DateTime.now(),
      };

      print(messageData);

      // Use update to add the message to the 'messages' array
      FirebaseFirestore.instance.collection('Chats').doc(widget.chatId).update({
        'messages': FieldValue.arrayUnion([messageData]),
      });

      // Clear the text field after sending the message
      _messageController.clear();
    }
  }


}

class MessageWidget extends StatelessWidget {
  const MessageWidget({Key? key, required this.senderName, required this.contents, required this.timestamp}) : super(key: key);

  final String senderName;
  final String contents;
  final Timestamp timestamp;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('$senderName - ${timestamp.toDate()}'),
          const SizedBox(height: 4),
          Text(contents),
          const Divider(),
        ],
      ),
    );
  }
}
