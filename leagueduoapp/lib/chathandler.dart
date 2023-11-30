import 'package:cloud_firestore/cloud_firestore.dart';

class Chat {
  List<String> members;
  List<Map<String, dynamic>> messages;

  Chat({
    this.members = const [],
    this.messages = const [],
  });

  static Chat fromMap(Map<String, dynamic> m) {
    return Chat(
      members: (m['members'] as List<dynamic>).cast<String>(),
      messages: List<Map<String, dynamic>>.from(m['messages']),
    );
  }


  Map<String, dynamic> toMap(){
    return {
      'members': members,
      'messages': messages,
    };
  }
}