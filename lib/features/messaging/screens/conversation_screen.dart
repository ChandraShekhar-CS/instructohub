import 'package:flutter/material.dart';
import 'package:emoji_picker_flutter/emoji_picker_flutter.dart';
import 'package:flutter/foundation.dart' as foundation;

import '../../../services/api_service.dart';
import '../../../services/enhanced_icon_service.dart';
import '../../../theme/dynamic_app_theme.dart';
import '../models/conversation_model.dart';
import '../models/message_model.dart';


class ConversationScreen extends StatefulWidget {
  final String token;
  final Conversation conversation;

  const ConversationScreen({
    Key? key,
    required this.token,
    required this.conversation,
  }) : super(key: key);

  @override
  _ConversationScreenState createState() => _ConversationScreenState();
}

class _ConversationScreenState extends State<ConversationScreen> {
  final TextEditingController _textController = TextEditingController();
  final ApiService _apiService = ApiService.instance;
  List<Message> _messages = [];
  bool _isLoading = true;
  bool _isSending = false;
  bool _emojiShowing = false;
  // This would come from a user service or auth provider
  final int _currentUserId = 1; // Replace with actual current user ID

  @override
  void initState() {
    super.initState();
    _fetchMessages();
  }
  
  @override
  void dispose() {
    _textController.dispose();
    super.dispose();
  }

  Future<void> _fetchMessages() async {
    setState(() => _isLoading = true);
    try {
      final response = await _apiService.getConversationMessages(widget.token, widget.conversation.id);
      if(mounted) {
        setState(() {
          _messages = response.map((data) => Message.fromJson(data)).toList().reversed.toList();
          _isLoading = false;
        });
      }
    } catch (e) {
      if(mounted) setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
    }
  }

  Future<void> _handleSendPressed() async {
    if (_textController.text.trim().isEmpty || _isSending) return;

    final text = _textController.text;
    setState(() {
      _isSending = true;
    });
    _textController.clear();

    try {
      await _apiService.sendMessage(widget.token, widget.conversation.otherUser.id, text);
      // For instant feedback, you could add the message locally before the API call returns
      // then update it with the real data. For now, we just refresh.
      await _fetchMessages();
    } catch (e) {
      // If sending fails, restore the text
      _textController.text = text;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to send: $e')));
    } finally {
      if (mounted) {
        setState(() {
          _isSending = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFEFE7DE), // WhatsApp-like background
      appBar: AppBar(
        backgroundColor: DynamicAppTheme.primary1,
        foregroundColor: Colors.white,
        title: Row(
          children: [
            CircleAvatar(
              backgroundImage: NetworkImage(widget.conversation.otherUser.profileimageurl),
            ),
            const SizedBox(width: 12),
            Text(widget.conversation.otherUser.fullname),
          ],
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : ListView.builder(
                    reverse: true,
                    padding: const EdgeInsets.all(8.0),
                    itemCount: _messages.length,
                    itemBuilder: (context, index) {
                      final message = _messages[index];
                      final isMe = message.useridfrom == _currentUserId;
                      return _buildMessageBubble(message, isMe);
                    },
                  ),
          ),
          _buildTextInputArea(),
          _buildEmojiPicker(),
        ],
      ),
    );
  }

  Widget _buildMessageBubble(Message message, bool isMe) {
    return Align(
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 4.0, horizontal: 8.0),
        padding: const EdgeInsets.symmetric(vertical: 10.0, horizontal: 14.0),
        decoration: BoxDecoration(
          color: isMe ? const Color(0xFFE7FFDB) : Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 5,
              offset: const Offset(0, 1),
            )
          ],
        ),
        child: Text(
          message.text,
          style: const TextStyle(fontSize: 16),
        ),
      ),
    );
  }

  Widget _buildTextInputArea() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 8.0),
      color: Colors.transparent,
      child: Row(
        children: [
          Expanded(
            child: Card(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(25.0),
              ),
              child: Row(
                children: [
                  IconButton(
                    icon: Icon(
                        DynamicIconService.instance.getIcon('sentiment_satisfied'),
                        color: DynamicAppTheme.textSecondary
                    ),
                    onPressed: () {
                      setState(() {
                         // Hide keyboard if it's open
                        FocusScope.of(context).unfocus();
                        _emojiShowing = !_emojiShowing;
                      });
                    },
                  ),
                  Expanded(
                    child: TextField(
                      controller: _textController,
                      decoration: const InputDecoration.collapsed(
                        hintText: 'Message',
                      ),
                      onTap: () {
                        if (_emojiShowing) {
                          setState(() {
                            _emojiShowing = false;
                          });
                        }
                      },
                    ),
                  ),
                  IconButton(
                    icon: Icon(DynamicIconService.instance.getIcon('attach_file'), color: DynamicAppTheme.textSecondary),
                    onPressed: () { /* Attachment logic here */ },
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 8.0),
          FloatingActionButton(
            mini: true,
            onPressed: _handleSendPressed,
            backgroundColor: DynamicAppTheme.secondary1,
            child: _isSending
                ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2,))
                : Icon(DynamicIconService.instance.getIcon('send'), color: Colors.white),
          ),
        ],
      ),
    );
  }

  Widget _buildEmojiPicker() {
    return Offstage(
      offstage: !_emojiShowing,
      child: SizedBox(
        height: 250,
        child: EmojiPicker(
          textEditingController: _textController,
           config: Config(
              height: 256,
              emojiViewConfig: EmojiViewConfig(
                 emojiSizeMax: 28 * (foundation.defaultTargetPlatform == TargetPlatform.iOS ? 1.20 : 1.0),
              ),
              swapCategoryAndBottomBar: false,
              skinToneConfig: const SkinToneConfig(),
              categoryViewConfig: const CategoryViewConfig(),
              bottomActionBarConfig: const BottomActionBarConfig(),
              searchViewConfig: const SearchViewConfig(),
           ),
        ),
      ),
    );
  }
}
