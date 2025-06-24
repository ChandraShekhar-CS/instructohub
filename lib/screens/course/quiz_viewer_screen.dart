import 'package:flutter/material.dart';
import 'package:flutter_html/flutter_html.dart';
import '../../services/dynamic_theme_service.dart';
import '../../services/enhanced_icon_service.dart';

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
    final themeService = DynamicThemeService.instance;
    final textTheme = Theme.of(context).textTheme;
    final String moduleName = module['name'] ?? 'Quiz';
    final quizData = foundContent ?? module;

    return Scaffold(
      appBar: AppBar(title: Text(moduleName)),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(themeService.getSpacing('md')),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Card(
              child: ListTile(
                leading: Icon(DynamicIconService.instance.getIcon('quiz'),
                    color: themeService.getColor('secondary1')),
                title: Text(moduleName, style: textTheme.titleMedium),
                subtitle: Text("Review the quiz details below",
                    style: textTheme.bodyMedium),
              ),
            ),
            SizedBox(height: themeService.getSpacing('md')),
            if (quizData['intro'] != null && quizData['intro'].isNotEmpty)
              Html(
                  data: quizData['intro'],
                  style: {"body": Style.fromTextStyle(textTheme.bodyMedium!)}),
            SizedBox(height: themeService.getSpacing('md')),
            _buildInfoSection(context, quizData),
            SizedBox(height: themeService.getSpacing('md')),
            _buildStartQuizCard(context, quizData),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoSection(BuildContext context, dynamic quizData) {
    final textTheme = Theme.of(context).textTheme;
    final themeService = DynamicThemeService.instance;
    return Card(
      child: Padding(
        padding: EdgeInsets.all(themeService.getSpacing('md')),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Details', style: textTheme.titleLarge),
            SizedBox(height: themeService.getSpacing('sm')),
            if (quizData['timelimit'] != null)
              _buildInfoRow(context,
                  iconKey: 'time',
                  label: 'Time Limit',
                  value: _formatDuration(quizData['timelimit'])),
            if (quizData['timeopen'] != null)
              _buildInfoRow(context,
                  iconKey: 'event_available',
                  label: 'Opens',
                  value: _formatDate(quizData['timeopen'])),
            if (quizData['timeclose'] != null)
              _buildInfoRow(context,
                  iconKey: 'event_busy',
                  label: 'Closes',
                  value: _formatDate(quizData['timeclose']),
                  valueColor: (quizData['timeclose'] * 1000) <
                          DateTime.now().millisecondsSinceEpoch
                      ? themeService.getColor('error')
                      : themeService.getColor('textPrimary')),
            if (quizData['attempts'] != null)
              _buildInfoRow(context,
                  iconKey: 'repeat',
                  label: 'Attempts allowed',
                  value: quizData['attempts'] == 0
                      ? 'Unlimited'
                      : '${quizData['attempts']}'),
            if (quizData['grademethod'] != null)
              _buildInfoRow(context,
                  iconKey: 'calculate',
                  label: 'Grading method',
                  value: _getGradingMethodText(quizData['grademethod'])),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(BuildContext context,
      {required String iconKey,
      required String label,
      required String value,
      Color? valueColor}) {
    final textTheme = Theme.of(context).textTheme;
    final themeService = DynamicThemeService.instance;
    return Padding(
      padding: EdgeInsets.symmetric(vertical: themeService.getSpacing('xs')),
      child: Row(
        children: [
          Icon(DynamicIconService.instance.getIcon(iconKey),
              size: 18, color: themeService.getColor('textSecondary')),
          SizedBox(width: themeService.getSpacing('sm')),
          Text('$label: ', style: textTheme.bodyMedium),
          Expanded(
              child: Text(value,
                  style: textTheme.bodyMedium
                      ?.copyWith(color: valueColor, fontWeight: FontWeight.w600))),
        ],
      ),
    );
  }

  Widget _buildStartQuizCard(BuildContext context, dynamic quizData) {
    final textTheme = Theme.of(context).textTheme;
    final now = DateTime.now();
    final timeOpen = quizData['timeopen'] != null && quizData['timeopen'] != 0
        ? DateTime.fromMillisecondsSinceEpoch(quizData['timeopen'] * 1000)
        : null;
    final timeClose =
        quizData['timeclose'] != null && quizData['timeclose'] != 0
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
        padding: EdgeInsets.all(DynamicThemeService.instance.getSpacing('md')),
        child: Column(
          children: [
            Text('Ready to Begin?', style: textTheme.titleLarge),
            SizedBox(height: DynamicThemeService.instance.getSpacing('md')),
            ElevatedButton.icon(
              icon: Icon(DynamicIconService.instance.getIcon('play_arrow')),
              label: Text(buttonText),
              onPressed: canStart
                  ? () {
                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                          content:
                              Text('Offline quiz attempts coming soon!')));
                    }
                  : null,
            ),
          ],
        ),
      ),
    );
  }

  String _getGradingMethodText(int grademethod) {
    switch (grademethod) {
      case 1:
        return 'Highest grade';
      case 2:
        return 'Average grade';
      case 3:
        return 'First attempt';
      case 4:
        return 'Last attempt';
      default:
        return 'Unknown';
    }
  }
}
