import 'package:flutter/material.dart';
import '../../services/dynamic_theme_service.dart';
import '../../services/enhanced_icon_service.dart';

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
        _contentController.text,
      );
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    final themeService = DynamicThemeService.instance;
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(
        title: Text('Edit "${widget.initialTitle}"'),
        actions: [
          IconButton(
            icon: Icon(DynamicIconService.instance.getIcon('save')),
            onPressed: _handleSave,
            tooltip: 'Save Changes',
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(themeService.getSpacing('md')),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text('Page Title', style: textTheme.titleLarge),
              SizedBox(height: themeService.getSpacing('sm')),
              TextFormField(
                controller: _titleController,
                decoration: const InputDecoration(
                  hintText: 'Enter the page title',
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Title cannot be empty.';
                  }
                  return null;
                },
              ),
              SizedBox(height: themeService.getSpacing('lg')),
              Text('Page Content', style: textTheme.titleLarge),
              SizedBox(height: themeService.getSpacing('sm')),
              TextFormField(
                controller: _contentController,
                decoration: const InputDecoration(
                  hintText: 'Enter the page content (HTML)',
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
              SizedBox(height: themeService.getSpacing('lg')),
              ElevatedButton.icon(
                onPressed: _handleSave,
                icon: Icon(DynamicIconService.instance.getIcon('save')),
                label: const Text('Save Changes'),
              )
            ],
          ),
        ),
      ),
    );
  }
}
