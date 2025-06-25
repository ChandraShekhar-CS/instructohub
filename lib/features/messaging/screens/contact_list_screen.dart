import 'package:flutter/material.dart';
import 'package:InstructoHub/services/api_service.dart';
import 'package:InstructoHub/services/dynamic_theme_service.dart';
import 'package:InstructoHub/features/messaging/models/chat_user_model.dart';
import 'package:InstructoHub/features/messaging/screens/conversation_screen.dart'; 

class ContactListScreen extends StatefulWidget {
  final String token;
  const ContactListScreen({Key? key, required this.token}) : super(key: key);

  @override
  _ContactListScreenState createState() => _ContactListScreenState();
}

class _ContactListScreenState extends State<ContactListScreen> {
  List<ChatUser> _contacts = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchContacts();
  }

  Future<void> _fetchContacts() async {
    try {
      final response = await ApiService.instance.getContacts(widget.token);
      final users = response.map((data) => ChatUser.fromJson(data)).toList();
      if (mounted) {
        setState(() {
          _contacts = users;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to load contacts: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Select Contact'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView.builder(
              itemCount: _contacts.length,
              itemBuilder: (context, index) {
                final user = _contacts[index];
                return ListTile(
                  leading: CircleAvatar(
                    radius: 25,
                    backgroundImage: NetworkImage(user.profileimageurl),
                  ),
                  title: Text(user.fullname,
                      style: Theme.of(context).textTheme.titleMedium),
                  onTap: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                          content: Text('Starting chat with ${user.fullname}')),
                    );
                  },
                );
              },
            ),
    );
  }
}
