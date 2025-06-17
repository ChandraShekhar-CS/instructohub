// lib/screens/viewers/edit_page_screen.dart
import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';

class EditPageScreen extends StatefulWidget {
  final String initialTitle;
  final String initialContent;
  final Function(String newTitle, String newContent) onSave;

  const EditPageScreen({
    required this.initialTitle,
    required this.initialContent,
    required this.onSave,
    Key? key,
  }) : super(key: key);

  @override
  _EditPageScreenState createState() => _EditPageScreenState();
}

class _EditPageScreenState extends State<EditPageScreen> {
  late TextEditingController _titleController;
  late TextEditingController _contentController;
  final _formKey = GlobalKey<FormState>();

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.initialTitle);
    // Correctly initialize the content controller with the raw HTML content
    _contentController = TextEditingController(text: widget.initialContent);
  }

  @override
  void dispose() {
    _titleController.dispose();
    _contentController.dispose();
    super.dispose();
  }

  void _handleSave() {
    if (_formKey.currentState!.validate()) {
      widget.onSave(
        _titleController.text,
        _contentController.text, // In a real app, this would be HTML content from a rich text editor
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        title: Text('Edit "${widget.initialTitle}"'),
        backgroundColor: AppTheme.secondary2,
        foregroundColor: AppTheme.offwhite,
        actions: [
          IconButton(
            icon: const Icon(Icons.save_alt_outlined),
            onPressed: _handleSave,
            tooltip: 'Save Changes',
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Page Title',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _titleController,
                decoration: const InputDecoration(
                  hintText: 'Enter the page title',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Title cannot be empty.';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 24),
              Text(
                'Page Content',
                 style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _contentController,
                decoration: const InputDecoration(
                  hintText: 'Enter the page content',
                  border: OutlineInputBorder(),
                  alignLabelWithHint: true,
                ),
                 maxLines: 15,
                 textAlignVertical: TextAlignVertical.top,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Content cannot be empty.';
                  }
                  return null;
                },
              ),
               const SizedBox(height: 24),
               ElevatedButton.icon(
                onPressed: _handleSave,
                icon: const Icon(Icons.save),
                label: const Text('Save Changes'),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16)
                ),
               )
            ],
          ),
        ),
      ),
    );
  }
}
