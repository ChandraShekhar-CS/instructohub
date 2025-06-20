import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../services/api_service.dart';
import '../services/icon_service.dart';
import '../theme/dynamic_app_theme.dart';
typedef AppTheme = DynamicAppTheme;

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
      // FIXED: Reverted to a direct API call to avoid the undefined_method error.
      final url = Uri.parse(
        '${ApiService.instance.baseUrl}?wsfunction=local_instructohub_get_user_course_progress&moodlewsrestformat=json&wstoken=${widget.token}'
      );
      
      final response = await http.post(url);
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (mounted) {
          setState(() {
            _metricsData = data is Map ? Map<String, dynamic>.from(data) : {};
            _isLoading = false;
          });
        }
      } else {
        throw Exception('Failed to load metrics from API');
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading metrics: ${e.toString()}'),
            backgroundColor: AppTheme.error,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppTheme.buildDynamicAppBar(title: 'Learning Metrics'),
      body: _isLoading
          ? Center(child: AppTheme.buildLoadingIndicator())
          : RefreshIndicator(
              onRefresh: _fetchMetricsData,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: EdgeInsets.all(AppTheme.spacingMd),
                child: Column(
                  children: [
                    AppTheme.buildStatCard(
                      title: 'Courses Enrolled',
                      value: _metricsData['enrolled_courses']?.toString() ?? '0',
                      iconKey: 'school',
                      color: AppTheme.secondary1,
                    ),
                    SizedBox(height: AppTheme.spacingMd),
                    AppTheme.buildStatCard(
                      title: 'Courses Completed',
                      value: _metricsData['completed_courses']?.toString() ?? '0',
                      iconKey: 'check_circle',
                      color: AppTheme.success,
                    ),
                    SizedBox(height: AppTheme.spacingMd),
                    AppTheme.buildStatCard(
                      title: 'In Progress',
                      value: _metricsData['in_progress_courses']?.toString() ?? '0',
                      iconKey: 'play_circle',
                      color: AppTheme.info,
                    ),
                    SizedBox(height: AppTheme.spacingMd),
                    AppTheme.buildStatCard(
                      title: 'Total Study Time',
                      value: _metricsData['total_time']?.toString() ?? '0 hours',
                      iconKey: 'time',
                      color: AppTheme.warning,
                    ),
                    SizedBox(height: AppTheme.spacingMd),
                    _buildProgressCard(),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildProgressCard() {
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
    
    return AppTheme.buildProgressCard(
      title: 'Overall Progress',
      progress: progress,
      progressColor: AppTheme.secondary1,
    );
  }
}
