import 'package:InstructoHub/features/messaging/models/chat_user_model.dart';
import 'package:InstructoHub/features/messaging/models/message_model.dart';

class Conversation {
  final int id;
  final List<ChatUser> members;
  final List<Message> messages;
  final int unreadcount;

  ChatUser get otherUser => members.first;
  Message get lastMessage => messages.first;

  Conversation({
    required this.id,
    required this.members,
    required this.messages,
    this.unreadcount = 0,
  });

  factory Conversation.fromJson(Map<String, dynamic> json) {
    return Conversation(
      id: json['id'] ?? 0,
      members: (json['members'] as List? ?? [])
          .map((m) => ChatUser.fromJson(m))
          .toList(),
      messages: (json['messages'] as List? ?? [])
          .map((m) => Message.fromJson(m))
          .toList(),
      unreadcount: json['unreadcount'] ?? 0,
    );
  }
}