import 'dart:ffi';
import 'dart:io';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:path/path.dart' as path;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:image_picker/image_picker.dart';
import 'package:leagueduoapp/chathandler.dart';
import 'package:permission_handler/permission_handler.dart';



Future<void> _requestCameraPermission() async {
  var status = await Permission.camera.status;
  if (!status.isGranted) {
    await Permission.camera.request();
  }
}

// Function to request photo library permission
Future<void> _requestPhotoLibraryPermission() async {
  var status = await Permission.photos.status;
  if (!status.isGranted) {
    await Permission.photos.request();
  }
}

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
        title: Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.centerLeft,
                end: Alignment.centerRight,
                colors: [Color.fromARGB(255, 33, 100, 35), Color.fromARGB(255, 79, 213, 84), Color.fromARGB(255, 33, 100, 35)],
                stops: [0.1, 0.5, 0.9],
              ),
            ),
            child: FutureBuilder<String>(
              future: getChatName(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return Text('Loading...'); // or any other loading indicator
                } else if (snapshot.hasError) {
                  return Text('Error: ${snapshot.error}');
                } else {
                  final chatName = snapshot.data;
                  return Text(
                    chatName != null ? chatName : 'Chat Name',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 30,
                    ),
                    
                    );
                }
              },
            ),
          ),
        
        
        
        
        backgroundColor: Colors.transparent, // Set the background color to transparent
        elevation: 0, // Set the elevation to 0 to make it invisible
        centerTitle: true, // Center the title
      ),
      body: Column(
        children: [
          Container(
            height: 1,
            color: Colors.black,
          ),
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
                      var isImage = message['isImage'] as bool;

                      // Determine if the message is from the current user
                      bool isCurrentUserMessage = message['senderId'] == widget.userId;

                      return MessageWidget(
                        senderName: senderName,
                        contents: contents,
                        timestamp: timestamp,
                        isCurrentUser: isCurrentUserMessage,
                        isImage: isImage,
                        chatId: widget.chatId,
                        userId: widget.userId,
                      );
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
      child: Container(
        decoration: BoxDecoration(
          color: const Color.fromARGB(255, 255, 253, 208), // Cream color
          borderRadius: BorderRadius.circular(16.0), // Rounded corners
        ),
        child: Row(
          children: [
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8.0),
                child: TextField(
                  controller: _messageController,
                  decoration: InputDecoration(
                    hintText: 'Type your message...',
                    border: InputBorder.none, // Remove default border
                  ),
                ),
              ),
            ),
            IconButton(
              icon: Icon(Icons.send),
              onPressed: () {
                _sendMessage(contents: _messageController.text, isImage: false);
              },
            ),
            IconButton(
              icon: Icon(Icons.camera_alt),
              onPressed: () {
                _takePicture();
              },
            ),

          ],
        ),
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
  
  void _takePicture() async {
    await _requestCameraPermission(); // Request camera permission before taking a picture

    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.camera);

    if (pickedFile != null) {
      _uploadImage(File(pickedFile.path));
    }
  }

  Future<void> _uploadImage(File imageFile) async {
    final fileName = path.basename(imageFile.path);
    final storageReference = FirebaseStorage.instance
        .ref()
        .child('chatImages/$fileName');

    try {
      await storageReference.putFile(imageFile);
      final downloadURL = await storageReference.getDownloadURL();

      // Send the downloadURL in the chat as a separate message
      _sendMessage(contents: downloadURL, isImage: true);

      // If there is text in the chat, send it as another message
      if (_messageController.text.isNotEmpty) {
        _sendMessage(contents: _messageController.text, isImage: false);
      }
    } catch (error) {
      print('Error uploading image: $error');
    }
  }

  void _sendMessage({required String contents, bool isImage = false}) async {
    FirebaseFirestore firestore = FirebaseFirestore.instance;
    CollectionReference accountsCollection = firestore.collection('Accounts');
    DocumentSnapshot userDocument = await accountsCollection.doc(widget.userId).get();

    Map<String, dynamic> messageData = {
      'contents': contents,
      'senderId': widget.userId,
      'senderName': userDocument['accountName'],
      'timestamp': DateTime.now(),
      'isImage': isImage, // Add isImage field to indicate if the message is an image
    };

    print(messageData);

    FirebaseFirestore.instance.collection('Chats').doc(widget.chatId).update({
      'messages': FieldValue.arrayUnion([messageData]),
    });

    // Clear the text field after sending the message
    _messageController.clear();
  }


}

class MessageWidget extends StatelessWidget {
  const MessageWidget({
    Key? key,
    required this.senderName,
    required this.contents,
    required this.timestamp,
    required this.isCurrentUser,
    required this.isImage,
    required this.chatId,
    required this.userId
  }) : super(key: key);

  final String senderName;
  final String contents;
  final Timestamp timestamp;
  final bool isCurrentUser;
  final bool isImage;
  final String chatId;
  final String userId;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        if (isImage) {
          _showImageModal(context);
        } else {
          _showTimestampModal(context);
        }
      },
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Column(
          crossAxisAlignment: isCurrentUser
              ? CrossAxisAlignment.end
              : CrossAxisAlignment.start,
          children: [
            Text(
              '$senderName',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: isCurrentUser ? Colors.blue : Colors.green,
              ),
            ),
            const SizedBox(height: 4),
            isImage
                ? Image.network(
                    contents,
                    width: 200, // Adjust the width as needed
                    height: 200, // Adjust the height as needed
                  )
                : Container(
                    padding: const EdgeInsets.all(8.0),
                    decoration: BoxDecoration(
                      color: isCurrentUser ? Colors.blue : Colors.green,
                      borderRadius: isCurrentUser
                          ? const BorderRadius.only(
                              topLeft: Radius.circular(8.0),
                              topRight: Radius.circular(8.0),
                              bottomLeft: Radius.circular(8.0),
                            )
                          : const BorderRadius.only(
                              topLeft: Radius.circular(8.0),
                              topRight: Radius.circular(8.0),
                              bottomRight: Radius.circular(8.0),
                            ),
                    ),
                    child: Text(
                      contents,
                      style: const TextStyle(
                        color: Colors.white,
                      ),
                    ),
                  ),
          ],
        ),
      ),
    );
  }

  void _showTimestampModal(BuildContext context) {
    showModalBottomSheet(
      context: context,
      builder: (BuildContext context) {
        return Container(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Message Timestamp',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8.0),
              Text('${timestamp.toDate()}'),
              const SizedBox(height: 8.0),
              if (isCurrentUser)
                ElevatedButton(
                  onPressed: () {
                    _deleteMessage();
                    Navigator.of(context).pop();
                  },
                  child: Text('Delete'),
                ),
              ElevatedButton(
                onPressed: () {
                  Navigator.of(context).pop();
                },
                child: Text('Close'),
              ),
            ],
          ),
        );
      },
    );
  }

  void _showImageModal(BuildContext context) {
    showModalBottomSheet(
      context: context,
      builder: (BuildContext context) {
        return Container(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Image',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8.0),
              Image.network(
                contents,
                width: 400, // Adjust the width as needed
                height: 400, // Adjust the height as needed
              ),
              const SizedBox(height: 8.0),
              if (isCurrentUser)
                ElevatedButton(
                  onPressed: () {
                    _deleteMessage();
                    Navigator.of(context).pop();
                  },
                  child: Text('Delete'),
                ),
              ElevatedButton(
                onPressed: () {
                  Navigator.of(context).pop();
                },
                child: Text('Close'),
              ),
            ],
          ),
        );
      },
    );
  }

  void _deleteMessage() async {
    try {
      print('Deleting message: $contents');

      FirebaseFirestore.instance.collection('Chats').doc(chatId).update({
        'messages': FieldValue.arrayRemove([
          {
            'contents': contents,
            'isImage': isImage,
            'senderId': userId,
            'senderName': senderName,
            'timestamp': timestamp,
          },
        ]),
      });

      if (isImage) {
        // Extract image name from the URL
        Uri uri = Uri.parse(contents);
        String imageName = uri.pathSegments.last;

        print('Deleting image: $imageName');
        await FirebaseStorage.instance.ref(imageName).delete();
        print('Image deleted successfully.');
      }
    } catch (error) {
      print('Error deleting message: $error');
    }
  }




}
