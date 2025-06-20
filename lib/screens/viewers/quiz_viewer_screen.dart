import 'package:flutter/material.dart';
import 'package:flutter_html/flutter_html.dart';
import '../../services/icon_service.dart';
import '../../theme/dynamic_app_theme.dart';
typedef AppTheme = DynamicAppTheme;

class QuizViewerScreen extends StatelessWidget {
  final dynamic module;
  final dynamic foundContent;
  final String token;
  final bool isOffline;

  const QuizViewerScreen({
    required this.module,
    this.foundContent,
    required this.token,
    this.isOffline = false,
    Key? key,
  }) : super(key: key);

  String _formatDate(int timestamp) {
    if (timestamp == 0) return 'Not set';
    final date = DateTime.fromMillisecondsSinceEpoch(timestamp * 1000);
    return '${date.day}/${date.month}/${date.year} at ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
  }

  String _formatDuration(int seconds) {
    if (seconds == 0) return 'No time limit';
    final duration = Duration(seconds: seconds);
    final hours = duration.inHours;
    final minutes = duration.inMinutes.remainder(60);
    return hours > 0 ? '${hours}h ${minutes}m' : '${minutes}m';
  }

  @override
  Widget build(BuildContext context) {
    final String moduleName = module['name'] ?? 'Quiz';
    // When offline, foundContent is the source of truth.
    final quizData = foundContent ?? module;

    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppTheme.buildDynamicAppBar(title: moduleName),
      body: SingleChildScrollView(
              padding: EdgeInsets.all(AppTheme.spacingMd),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  AppTheme.buildInfoCard(iconKey: 'quiz', title: moduleName, subtitle: "Review the quiz details below"),
                  SizedBox(height: AppTheme.spacingMd),
                  if (quizData['intro'] != null && quizData['intro'].isNotEmpty)
                    Html(data: quizData['intro'], style: {"body": Style(fontSize: FontSize(AppTheme.fontSizeBase), color: AppTheme.textSecondary)}),
                  SizedBox(height: AppTheme.spacingMd),
                  _buildInfoSection(quizData),
                  SizedBox(height: AppTheme.spacingMd),
                  _buildStartQuizCard(quizData, context),
                ],
              ),
            ),
    );
  }

  Widget _buildInfoSection(dynamic quizData) {
    return Card(
      child: Padding(
        padding: EdgeInsets.all(AppTheme.spacingMd),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Details', style: TextStyle(fontSize: AppTheme.fontSizeLg, fontWeight: FontWeight.bold, color: AppTheme.textPrimary)),
            SizedBox(height: AppTheme.spacingSm),
            if (quizData['timelimit'] != null)
              _buildInfoRow(iconKey: 'time', label: 'Time Limit', value: _formatDuration(quizData['timelimit'])),
            if (quizData['timeopen'] != null)
              _buildInfoRow(iconKey: 'event_available', label: 'Opens', value: _formatDate(quizData['timeopen'])),
            if (quizData['timeclose'] != null)
              _buildInfoRow(
                iconKey: 'event_busy',
                label: 'Closes',
                value: _formatDate(quizData['timeclose']),
                valueColor: (quizData['timeclose'] * 1000) < DateTime.now().millisecondsSinceEpoch ? AppTheme.error : AppTheme.textPrimary,
              ),
            if (quizData['attempts'] != null)
              _buildInfoRow(iconKey: 'repeat', label: 'Attempts allowed', value: quizData['attempts'] == 0 ? 'Unlimited' : '${quizData['attempts']}'),
            if (quizData['grademethod'] != null)
              _buildInfoRow(iconKey: 'calculate', label: 'Grading method', value: _getGradingMethodText(quizData['grademethod'])),
          ],
        ),
      ),
    );
  }
  
  Widget _buildInfoRow({required String iconKey, required String label, required String value, Color? valueColor}) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: AppTheme.spacingXs),
      child: Row(
        children: [
          Icon(IconService.instance.getIcon(iconKey), size: 18, color: AppTheme.textSecondary),
          SizedBox(width: AppTheme.spacingSm),
          Text('$label: ', style: TextStyle(color: AppTheme.textSecondary)),
          Expanded(child: Text(value, style: TextStyle(color: valueColor ?? AppTheme.textPrimary, fontWeight: FontWeight.w600))),
        ],
      ),
    );
  }

  Widget _buildStartQuizCard(dynamic quizData, BuildContext context) {
    final now = DateTime.now();
    final timeOpen = quizData['timeopen'] != null && quizData['timeopen'] != 0 
        ? DateTime.fromMillisecondsSinceEpoch(quizData['timeopen'] * 1000) 
        : null;
    final timeClose = quizData['timeclose'] != null && quizData['timeclose'] != 0 
        ? DateTime.fromMillisecondsSinceEpoch(quizData['timeclose'] * 1000) 
        : null;

    bool canStart = true;
    String buttonText = 'Attempt Quiz';
    
    if (isOffline) {
        buttonText = 'Offline: Start Quiz';
    } else if (timeOpen != null && now.isBefore(timeOpen)) {
      canStart = false;
      buttonText = 'Quiz Not Yet Available';
    } else if (timeClose != null && now.isAfter(timeClose)) {
      canStart = false;
      buttonText = 'Quiz Closed';
    }

    return Card(
      child: Padding(
        padding: EdgeInsets.all(AppTheme.spacingMd),
        child: Column(
          children: [
            Text('Ready to Begin?', style: TextStyle(fontSize: AppTheme.fontSizeLg, fontWeight: FontWeight.bold, color: AppTheme.textPrimary)),
            SizedBox(height: AppTheme.spacingMd),
            AppTheme.buildActionButton(
              text: buttonText,
              iconKey: 'play_arrow',
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Offline quiz attempts coming soon!')));
              },
              isEnabled: canStart,
            ),
          ],
        ),
      ),
    );
  }

  String _getGradingMethodText(int grademethod) {
    switch (grademethod) {
      case 1: return 'Highest grade';
      case 2: return 'Average grade';
      case 3: return 'First attempt';
      case 4: return 'Last attempt';
      default: return 'Unknown';
    }
  }
}
