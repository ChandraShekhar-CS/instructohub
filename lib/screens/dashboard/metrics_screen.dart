import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../../services/api_service.dart';
import '../../services/dynamic_theme_service.dart';
import '../../services/enhanced_icon_service.dart';

class MetricsScreen extends StatefulWidget {
  final String token;

  const MetricsScreen({required this.token, Key? key}) : super(key: key);

  @override
  _MetricsScreenState createState() => _MetricsScreenState();
}

class _MetricsScreenState extends State<MetricsScreen> {
  bool _isLoading = true;
  Map<String, dynamic> _metricsData = {};
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _fetchMetricsData();
  }

  Future<void> _fetchMetricsData() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final data = await ApiService.instance.getUserProgress(widget.token);
      if (mounted) {
        setState(() {
          _metricsData = data ?? {};
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _errorMessage = e.toString();
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading metrics: ${e.toString()}'),
            backgroundColor: DynamicThemeService.instance.getColor('error'),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Learning Metrics')),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _fetchMetricsData,
              child: _errorMessage != null
                  ? _buildErrorView()
                  : SingleChildScrollView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        children: [
                          _buildStatCard(
                            title: 'Courses Enrolled',
                            value: _metricsData['totalcourses']?.toString() ?? '0',
                            iconKey: 'school',
                            color: DynamicThemeService.instance.getColor('secondary1'),
                          ),
                          const SizedBox(height: 16.0),
                          _buildStatCard(
                            title: 'Courses Completed',
                            value: _metricsData['completedcoursescount']?.toString() ?? '0',
                            iconKey: 'check_circle',
                            color: DynamicThemeService.instance.getColor('success'),
                          ),
                          const SizedBox(height: 16.0),
                          _buildStatCard(
                            title: 'In Progress',
                            value: _metricsData['activecoursescount']?.toString() ?? '0',
                            iconKey: 'play_circle',
                            color: DynamicThemeService.instance.getColor('info'),
                          ),
                          const SizedBox(height: 16.0),
                          _buildStatCard(
                            title: 'Not Started',
                            value: _metricsData['notstartedcount']?.toString() ?? '0',
                            iconKey: 'schedule',
                            color: DynamicThemeService.instance.getColor('textSecondary'),
                          ),
                          const SizedBox(height: 16.0),
                          _buildProgressCard(),
                        ],
                      ),
                    ),
            ),
    );
  }

  Widget _buildErrorView() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error, color: Colors.red, size: 50),
            const SizedBox(height: 16),
            const Text("Failed to load metrics.", style: TextStyle(fontSize: 18)),
            const SizedBox(height: 8),
            Text(_errorMessage ?? 'An unknown error occurred.'),
            const SizedBox(height: 16),
            ElevatedButton(onPressed: _fetchMetricsData, child: const Text("Try Again"))
          ],
        ),
      ),
    );
  }

  Widget _buildStatCard({
    required String title,
    required String value,
    required String iconKey,
    required Color color,
  }) {
    final themeService = DynamicThemeService.instance;
    final textTheme = Theme.of(context).textTheme;

    return Card(
      elevation: 2.0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(themeService.getBorderRadius('medium')),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(themeService.getBorderRadius('small')),
              ),
              child: Icon(DynamicIconService.instance.getIcon(iconKey), color: color, size: 24),
            ),
            const SizedBox(width: 16.0),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: textTheme.titleMedium),
                const SizedBox(height: 4.0),
                Text(value, style: textTheme.headlineSmall?.copyWith(color: color)),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProgressCard() {
    final themeService = DynamicThemeService.instance;
    final textTheme = Theme.of(context).textTheme;
    double progress = 0.0;
    try {
      var progressValue = _metricsData['overallprogress'];
      if (progressValue is String) {
        progress = double.tryParse(progressValue) ?? 0.0;
      } else if (progressValue is num) {
        progress = progressValue.toDouble();
      }
    } catch (e) {
      progress = 0.0;
    }

    return Card(
      elevation: 2.0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(themeService.getBorderRadius('medium')),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Overall Progress', style: textTheme.titleLarge),
            const SizedBox(height: 16.0),
            Row(
              children: [
                Expanded(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(themeService.getBorderRadius('large')),
                    child: LinearProgressIndicator(
                      value: progress / 100.0,
                      minHeight: 12,
                      backgroundColor: themeService.getColor('textSecondary').withOpacity(0.2),
                      valueColor: AlwaysStoppedAnimation<Color>(themeService.getColor('secondary1')),
                    ),
                  ),
                ),
                const SizedBox(width: 16.0),
                Text('${progress.toStringAsFixed(0)}%', style: textTheme.titleLarge?.copyWith(color: themeService.getColor('secondary1'))),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
