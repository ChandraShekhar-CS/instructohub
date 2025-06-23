import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';

import '../../../services/enhanced_icon_service.dart';
import '../../../theme/dynamic_app_theme.dart';
import '../providers/messaging_provider.dart';
import '../models/conversation_model.dart';
import './conversation_screen.dart';
import './contact_list_screen.dart';

class ChatListScreen extends StatelessWidget {
  final String token;
  const ChatListScreen({Key? key, required this.token}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // We use ChangeNotifierProvider to create and provide the MessagingProvider
    // to this part of the widget tree.
    return ChangeNotifierProvider(
      create: (_) => MessagingProvider(token),
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Messages'),
          backgroundColor: DynamicAppTheme.primary1,
          foregroundColor: Colors.white,
          elevation: 0.7,
        ),
        body: Consumer<MessagingProvider>(
          builder: (context, provider, child) {
            if (provider.isLoading && provider.conversations.isEmpty) {
              return const Center(child: CircularProgressIndicator());
            }

            if (provider.conversations.isEmpty) {
              // FIX: Removed 'const' keyword because the style uses a non-constant value.
              return Center(
                child: Text(
                  'No conversations yet.',
                  style: TextStyle(color: DynamicAppTheme.textSecondary),
                ),
              );
            }

            return ListView.builder(
              itemCount: provider.conversations.length,
              itemBuilder: (context, index) {
                final conversation = provider.conversations[index];
                return _buildConversationTile(context, conversation, token);
              },
            );
          },
        ),
        floatingActionButton: FloatingActionButton(
          onPressed: () {
             Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (context) => ContactListScreen(token: token),
                ),
            );
          },
          backgroundColor: DynamicAppTheme.secondary1,
          child: Icon(DynamicIconService.instance.getIcon('add'), color: Colors.white),
        ),
      ),
    );
  }

  Widget _buildConversationTile(BuildContext context, Conversation conversation, String token) {
    // Helper to format the timestamp of the last message
    String formatTimestamp(int timestamp) {
        var dt = DateTime.fromMillisecondsSinceEpoch(timestamp * 1000);
        return DateFormat('h:mm a').format(dt);
    }

    return Column(
      children: [
        ListTile(
          onTap: () {
            Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (context) => ConversationScreen(
                        token: token,
                        conversation: conversation,
                    ),
                ),
            );
          },
          leading: CircleAvatar(
            radius: 28,
            backgroundImage: NetworkImage(conversation.otherUser.profileimageurl),
          ),
          title: Text(
            conversation.otherUser.fullname,
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          subtitle: Text(
            conversation.lastMessage.text,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          trailing: Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                formatTimestamp(conversation.lastMessage.timecreated),
                style: TextStyle(
                  color: conversation.unreadcount > 0
                      ? DynamicAppTheme.secondary1
                      : DynamicAppTheme.textSecondary,
                  fontSize: 12,
                ),
              ),
              if (conversation.unreadcount > 0) ...[
                const SizedBox(height: 4),
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration( // FIX: Removed 'const' keyword
                    color: DynamicAppTheme.secondary1,
                    shape: BoxShape.circle,
                  ),
                  child: Text(
                    conversation.unreadcount.toString(),
                    style: const TextStyle(color: Colors.white, fontSize: 12),
                  ),
                ),
              ],
            ],
          ),
        ),
        const Divider(height: 1, indent: 80),
      ],
    );
  }
}