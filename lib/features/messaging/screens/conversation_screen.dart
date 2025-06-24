import 'package:flutter/material.dart';
import 'package:emoji_picker_flutter/emoji_picker_flutter.dart';
import 'package:flutter/foundation.dart' as foundation;
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

import '../../../services/api_service.dart';
import '../../../services/dynamic_theme_service.dart';
import '../../../services/enhanced_icon_service.dart';
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

  // This will be dynamically retrieved from local storage.
  int _currentUserId = -1;

  @override
  void initState() {
    super.initState();
    _loadInitialData();
  }

  Future<void> _loadInitialData() async {
    await _loadCurrentUser();
    await _fetchMessages();
  }
  
  // Fetches the current user's ID from SharedPreferences.
  Future<void> _loadCurrentUser() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final userInfoString = prefs.getString('userInfo');
      if (userInfoString != null) {
        final userInfo = json.decode(userInfoString);
        if (mounted) {
          setState(() {
            _currentUserId = userInfo['userid'];
          });
        }
      }
    } catch (e) {
      if(mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Could not load user data: $e')));
      }
    }
  }

  @override
  void dispose() {
    _textController.dispose();
    super.dispose();
  }

  Future<void> _fetchMessages() async {
    // Ensure we have a valid user ID before fetching.
    if (_currentUserId == -1) {
       if (mounted) {
         setState(() => _isLoading = false);
         ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Could not verify user. Cannot load messages.')));
       }
       return;
    }

    setState(() => _isLoading = true);
    try {
      final response = await _apiService.getConversationMessages(
          widget.token, widget.conversation.id);
      if (mounted) {
        setState(() {
          _messages = response
              .map((data) => Message.fromJson(data))
              .toList()
              .reversed
              .toList();
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Error: $e')));
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
      await _apiService.sendMessage(
          widget.token, widget.conversation.otherUser.id, text);
      await _fetchMessages();
    } catch (e) {
      _textController.text = text;
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Failed to send: $e')));
      }
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
    final themeService = DynamicThemeService.instance;

    return Scaffold(
      backgroundColor: themeService.getColor('background'),
      appBar: AppBar(
        title: Row(
          children: [
            CircleAvatar(
              backgroundImage:
                  NetworkImage(widget.conversation.otherUser.profileimageurl),
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
    final themeService = DynamicThemeService.instance;
    return Align(
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 4.0, horizontal: 8.0),
        padding: const EdgeInsets.symmetric(vertical: 10.0, horizontal: 14.0),
        decoration: BoxDecoration(
          color: isMe
              ? themeService.getColor('secondary1').withOpacity(0.8)
              : themeService.getColor('cardColor'),
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
          style: TextStyle(
              fontSize: 16,
              color:
                  isMe ? Colors.white : themeService.getColor('textPrimary')),
        ),
      ),
    );
  }

  Widget _buildTextInputArea() {
    final themeService = DynamicThemeService.instance;
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
                        DynamicIconService.instance
                            .getIcon('sentiment_satisfied'),
                        color: themeService.getColor('textSecondary')),
                    onPressed: () {
                      setState(() {
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
                    icon: Icon(
                        DynamicIconService.instance.getIcon('attach_file'),
                        color: themeService.getColor('textSecondary')),
                    onPressed: () {},
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 8.0),
          FloatingActionButton(
            mini: true,
            onPressed: _handleSendPressed,
            child: _isSending
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      color: Colors.white,
                      strokeWidth: 2,
                    ))
                : Icon(DynamicIconService.instance.getIcon('send'),
                    color: Colors.white),
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
              emojiSizeMax: 28 *
                  (foundation.defaultTargetPlatform == TargetPlatform.iOS
                      ? 1.20
                      : 1.0),
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
