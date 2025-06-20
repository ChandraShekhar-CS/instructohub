import 'package:flutter/material.dart';
import '../../services/icon_service.dart';
import '../../theme/dynamic_app_theme.dart';
typedef AppTheme = DynamicAppTheme;

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
      Navigator.pop(context); // Go back after saving
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppTheme.buildDynamicAppBar(
        title: 'Edit "${widget.initialTitle}"',
        actions: [
          IconButton(
            icon: Icon(IconService.instance.getIcon('save')),
            onPressed: _handleSave,
            tooltip: 'Save Changes',
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(AppTheme.spacingMd),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Page Title',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: AppTheme.fontSizeLg, color: AppTheme.textPrimary),
              ),
              SizedBox(height: AppTheme.spacingSm),
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
              SizedBox(height: AppTheme.spacingLg),
              Text(
                'Page Content',
                 style: TextStyle(fontWeight: FontWeight.bold, fontSize: AppTheme.fontSizeLg, color: AppTheme.textPrimary),
              ),
              SizedBox(height: AppTheme.spacingSm),
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
              SizedBox(height: AppTheme.spacingLg),
              AppTheme.buildActionButton(
                onPressed: _handleSave,
                iconKey: 'save',
                text: 'Save Changes',
              )
            ],
          ),
        ),
      ),
    );
  }
}
