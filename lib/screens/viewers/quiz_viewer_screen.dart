import 'package:flutter/material.dart';
import 'package:flutter_html/flutter_html.dart';
import '../../theme/app_theme.dart';

class QuizViewerScreen extends StatelessWidget {
  final dynamic module;
  final dynamic foundContent;
  final String token;

  const QuizViewerScreen({
    required this.module,
    this.foundContent,
    required this.token,
    Key? key,
  }) : super(key: key);

  String _formatDate(int timestamp) {
    if (timestamp == 0) return 'No time limit';
    final date = DateTime.fromMillisecondsSinceEpoch(timestamp * 1000);
    return '${date.day}/${date.month}/${date.year} at ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
  }

  String _formatDuration(int seconds) {
    if (seconds == 0) return 'No time limit';
    final duration = Duration(seconds: seconds);
    final hours = duration.inHours;
    final minutes = duration.inMinutes.remainder(60);
    
    if (hours > 0) {
      return '${hours}h ${minutes}m';
    } else {
      return '${minutes}m';
    }
  }

  @override
  Widget build(BuildContext context) {
    final String moduleName = module['name'] ?? 'Quiz';
    final quizData = foundContent ?? module;

    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        title: Text(moduleName),
        backgroundColor: AppTheme.secondary2,
        foregroundColor: AppTheme.offwhite,
      ),
      body: foundContent == null 
        ? Center(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.quiz_outlined, size: 80, color: AppTheme.primary2),
                  const SizedBox(height: 20),
                  Text('Quiz content not available', 
                       style: Theme.of(context).textTheme.headlineSmall),
                ],
              ),
            ),
          )
        : SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(8.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.all(12.0),
                    decoration: BoxDecoration(
                      color: AppTheme.secondary2.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppTheme.secondary2.withOpacity(0.2))
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: AppTheme.secondary2.withOpacity(0.2),
                                borderRadius: BorderRadius.circular(8)
                              ),
                              child: const Icon(Icons.quiz_outlined, color: AppTheme.secondary2, size: 24),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                moduleName,
                                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                                  color: AppTheme.primary1,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ),
                        if (quizData['intro'] != null && quizData['intro'].isNotEmpty) ...[
                          const SizedBox(height: 12),
                          Html(
                            data: quizData['intro'],
                            style: {
                              "body": Style(
                                fontSize: FontSize(AppTheme.fontSizeBase),
                                color: AppTheme.textSecondary,
                                margin: Margins.zero,
                              ),
                            },
                          ),
                        ]
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),

                  Row(
                    children: [
                      Expanded(
                        child: _buildInfoCard(
                          icon: Icons.quiz,
                          title: 'Questions',
                          content: '${quizData['questions'] ?? 0}',
                          color: AppTheme.primary2,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _buildInfoCard(
                          icon: Icons.grade,
                          title: 'Max Grade',
                          content: '${quizData['grade'] ?? 0}',
                          color: AppTheme.primary2,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),

                  if (quizData['timelimit'] != null) ...[
                    _buildInfoCard(
                      icon: Icons.timer,
                      title: 'Time Limit',
                      content: _formatDuration(quizData['timelimit']),
                      color: AppTheme.primary2,
                    ),
                    const SizedBox(height: 8),
                  ],

                  if (quizData['timeopen'] != null && quizData['timeopen'] != 0) ...[
                    _buildInfoCard(
                      icon: Icons.schedule,
                      title: 'Opens',
                      content: _formatDate(quizData['timeopen']),
                      color: AppTheme.primary2,
                    ),
                    const SizedBox(height: 8),
                  ],

                  if (quizData['timeclose'] != null && quizData['timeclose'] != 0) ...[
                    _buildInfoCard(
                      icon: Icons.schedule_outlined,
                      title: 'Closes',
                      content: _formatDate(quizData['timeclose']),
                      color: quizData['timeclose'] != 0 && 
                             DateTime.fromMillisecondsSinceEpoch(quizData['timeclose'] * 1000).isBefore(DateTime.now())
                             ? Colors.red : AppTheme.primary2,
                    ),
                    const SizedBox(height: 8),
                  ],

                  _buildAttemptsCard(quizData),
                  
                  const SizedBox(height: 12),
                  _buildStartQuizCard(quizData, context),
                ],
              ),
            ),
          ),
    );
  }

  Widget _buildInfoCard({
    required IconData icon,
    required String title,
    required String content,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(12.0),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: AppTheme.fontSizeSm,
                    color: color,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  content,
                  style: TextStyle(
                    fontSize: AppTheme.fontSizeBase,
                    color: AppTheme.primary1,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAttemptsCard(dynamic quizData) {
    return Container(
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: AppTheme.cardColor,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            spreadRadius: 1,
            blurRadius: 10,
          )
        ]
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Attempt Information',
            style: TextStyle(
              fontSize: AppTheme.fontSizeLg,
              fontWeight: FontWeight.bold,
              color: AppTheme.primary1,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Icon(Icons.repeat, color: AppTheme.primary2, size: 20),
              const SizedBox(width: 8),
              Text(
                'Attempts allowed: ${quizData['attempts'] == 0 ? 'Unlimited' : quizData['attempts'] ?? 1}',
                style: TextStyle(
                  fontSize: AppTheme.fontSizeBase,
                  color: AppTheme.primary1,
                ),
              ),
            ],
          ),
          if (quizData['grademethod'] != null) ...[
            const SizedBox(height: 8),
            Row(
              children: [
                Icon(Icons.calculate, color: AppTheme.primary2, size: 20),
                const SizedBox(width: 8),
                Text(
                  'Grading method: ${_getGradingMethodText(quizData['grademethod'])}',
                  style: TextStyle(
                    fontSize: AppTheme.fontSizeBase,
                    color: AppTheme.primary1,
                  ),
                ),
              ],
            ),
          ],
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
    String buttonText = 'Start Quiz';
    Color buttonColor = AppTheme.secondary2;
    
    if (timeOpen != null && now.isBefore(timeOpen)) {
      canStart = false;
      buttonText = 'Quiz not yet available';
      buttonColor = Colors.grey;
    } else if (timeClose != null && now.isAfter(timeClose)) {
      canStart = false;
      buttonText = 'Quiz closed';
      buttonColor = Colors.red;
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: AppTheme.cardColor,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            spreadRadius: 1,
            blurRadius: 10,
          )
        ]
      ),
      child: Column(
        children: [
          Text(
            'Ready to take the quiz?',
            style: TextStyle(
              fontSize: AppTheme.fontSizeLg,
              fontWeight: FontWeight.bold,
              color: AppTheme.primary1,
            ),
          ),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: canStart ? () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Quiz functionality coming soon!')),
              );
            } : null,
            icon: const Icon(Icons.play_arrow),
            label: Text(buttonText),
            style: ElevatedButton.styleFrom(
              backgroundColor: buttonColor,
              foregroundColor: AppTheme.offwhite,
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
              textStyle: const TextStyle(
                fontSize: AppTheme.fontSizeBase,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
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