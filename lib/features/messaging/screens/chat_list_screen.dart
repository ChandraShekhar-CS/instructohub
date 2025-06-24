import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';

import '../../../services/dynamic_theme_service.dart';
import '../../../services/enhanced_icon_service.dart';
import '../providers/messaging_provider.dart';
import '../models/conversation_model.dart';
import './conversation_screen.dart';
import './contact_list_screen.dart';

class ChatListScreen extends StatelessWidget {
  final String token;
  const ChatListScreen({Key? key, required this.token}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final themeService = DynamicThemeService.instance;

    return ChangeNotifierProvider(
      create: (_) => MessagingProvider(token),
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Messages'),
        ),
        body: Consumer<MessagingProvider>(
          builder: (context, provider, child) {
            if (provider.isLoading && provider.conversations.isEmpty) {
              return const Center(child: CircularProgressIndicator());
            }

            if (provider.conversations.isEmpty) {
              return Center(
                child: Text(
                  'No conversations yet.',
                  style: Theme.of(context).textTheme.bodyMedium,
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
          child: Icon(DynamicIconService.instance.getIcon('add'),
              color: Colors.white),
        ),
      ),
    );
  }

  Widget _buildConversationTile(
      BuildContext context, Conversation conversation, String token) {
    final themeService = DynamicThemeService.instance;
    final textTheme = Theme.of(context).textTheme;

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
            backgroundImage:
                NetworkImage(conversation.otherUser.profileimageurl),
          ),
          title: Text(
            conversation.otherUser.fullname,
            style: textTheme.titleMedium,
          ),
          subtitle: Text(
            conversation.lastMessage.text,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: textTheme.bodySmall,
          ),
          trailing: Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                formatTimestamp(conversation.lastMessage.timecreated),
                style: textTheme.bodySmall?.copyWith(
                  color: conversation.unreadcount > 0
                      ? themeService.getColor('secondary1')
                      : themeService.getColor('textSecondary'),
                ),
              ),
              if (conversation.unreadcount > 0) ...[
                const SizedBox(height: 4),
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: themeService.getColor('secondary1'),
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
