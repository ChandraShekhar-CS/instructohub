import 'package:flutter/material.dart';
import 'package:InstructoHub/services/api_service.dart';
import 'package:InstructoHub/features/messaging/models/conversation_model.dart';
import 'package:InstructoHub/features/messaging/models/message_model.dart';

class MessagingProvider with ChangeNotifier {
  final ApiService _apiService = ApiService.instance;
  final String _token;

  List<Conversation> _conversations = [];
  List<Conversation> get conversations => _conversations;

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  MessagingProvider(this._token) {
    fetchConversations();
  }

  Future<void> fetchConversations() async {
    _isLoading = true;
    notifyListeners();
    try {
      final response = await _apiService.getConversations(_token);
      _conversations =
          response.map((data) => Conversation.fromJson(data)).toList();
    } catch (e) {
      print("Error in fetchConversations: $e");
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<List<Message>> fetchMessagesForConversation(int conversationId) async {
    try {
      final response =
          await _apiService.getConversationMessages(_token, conversationId);
      return response.map((data) => Message.fromJson(data)).toList();
    } catch (e) {
      print("Error in fetchMessagesForConversation: $e");
      return [];
    }
  }

  Future<bool> sendMessage(int recipientId, String text) async {
    try {
      await _apiService.sendMessage(_token, recipientId, text);
      // Refresh conversations to show the new message
      await fetchConversations();
      return true;
    } catch (e) {
      print("Error sending message: $e");
      return false;
    }
  }
}
