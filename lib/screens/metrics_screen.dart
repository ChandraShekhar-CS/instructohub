import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../theme/app_theme.dart';

class MetricsScreen extends StatefulWidget {
  final String token;

  const MetricsScreen({required this.token, Key? key}) : super(key: key);

  @override
  _MetricsScreenState createState() => _MetricsScreenState();
}

class _MetricsScreenState extends State<MetricsScreen> {
  bool _isLoading = true;
  Map<String, dynamic> _metricsData = {};

  @override
  void initState() {
    super.initState();
    _fetchMetricsData();
  }

  Future<void> _fetchMetricsData() async {
    setState(() => _isLoading = true);
    
    try {
      final url = Uri.parse(
        'https://moodle.instructohub.com/webservice/rest/server.php?wsfunction=local_instructohub_get_user_course_progress&moodlewsrestformat=json&wstoken=${widget.token}'
      );
      
      final response = await http.post(url);
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        print('Metrics response: $data'); // Debug log
        
        if (mounted) {
          setState(() {
            _metricsData = data is Map ? Map<String, dynamic>.from(data) : {};
            _isLoading = false;
          });
        }
      }
    } catch (e) {
      print('Metrics error: $e'); // Debug log
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading metrics: ${e.toString()}')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Learning Metrics'),
        backgroundColor: AppTheme.secondary1,
        foregroundColor: AppTheme.offwhite,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _fetchMetricsData,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    _buildMetricCard(
                      'Courses Enrolled',
                      _metricsData['enrolled_courses']?.toString() ?? '0',
                      Icons.school,
                      AppTheme.secondary1,
                    ),
                    const SizedBox(height: 16),
                    _buildMetricCard(
                      'Courses Completed',
                      _metricsData['completed_courses']?.toString() ?? '0',
                      Icons.check_circle,
                      AppTheme.secondary2,
                    ),
                    const SizedBox(height: 16),
                    _buildMetricCard(
                      'In Progress',
                      _metricsData['in_progress_courses']?.toString() ?? '0',
                      Icons.play_circle,
                      AppTheme.navselected,
                    ),
                    const SizedBox(height: 16),
                    _buildMetricCard(
                      'Total Study Time',
                      _metricsData['total_time']?.toString() ?? '0 hours',
                      Icons.access_time,
                      AppTheme.primary1,
                    ),
                    const SizedBox(height: 16),
                    _buildProgressCard(),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildMetricCard(String title, String value, IconData icon, Color color) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Container(
        padding: const EdgeInsets.all(20),
        width: double.infinity,
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, color: color, size: 28),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 14,
                      color: AppTheme.primary2,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    value,
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.primary1,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProgressCard() {
    // Safely handle progress value conversion
    double progress = 0.0;
    try {
      var progressValue = _metricsData['overall_progress'];
      if (progressValue is String) {
        progress = double.tryParse(progressValue) ?? 0.0;
      } else if (progressValue is num) {
        progress = progressValue.toDouble();
      }
    } catch (e) {
      progress = 0.0;
    }
    
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Container(
        padding: const EdgeInsets.all(20),
        width: double.infinity,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Overall Progress',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppTheme.primary1,
              ),
            ),
            const SizedBox(height: 16),
            LinearProgressIndicator(
              value: progress / 100,
              backgroundColor: AppTheme.loginBgLeft,
              valueColor: const AlwaysStoppedAnimation<Color>(AppTheme.secondary1),
              minHeight: 8,
            ),
            const SizedBox(height: 8),
            Text(
              '${progress.toStringAsFixed(1)}% Complete',
              style: const TextStyle(
                fontSize: 14,
                color: AppTheme.primary2,
              ),
            ),
          ],
        ),
      ),
    );
  }
}