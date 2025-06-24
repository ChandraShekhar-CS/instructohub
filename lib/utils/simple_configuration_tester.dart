// File: lib/utils/simple_configuration_tester.dart

import 'package:flutter/material.dart';
import '../services/configuration_service.dart';
import '../theme/app_theme.dart';

class SimpleConfigurationTester extends StatefulWidget {
  const SimpleConfigurationTester({super.key});

  @override
  State<SimpleConfigurationTester> createState() =>
      _SimpleConfigurationTesterState();
}

class _SimpleConfigurationTesterState extends State<SimpleConfigurationTester> {
  final _domainController = TextEditingController();
  bool _isLoading = false;
  String _status = 'Ready to test basic configuration';
  LMSConfiguration? _config;

  @override
  void dispose() {
    _domainController.dispose();
    super.dispose();
  }

  Future<void> _testConfiguration() async {
    if (_domainController.text.trim().isEmpty) {
      setState(() => _status = 'Please enter a domain');
      return;
    }

    setState(() {
      _isLoading = true;
      _status = 'Testing configuration...';
    });

    try {
      // Initialize configuration service
      await ConfigurationService.instance.initialize();

      // Test domain configuration
      await ConfigurationService.instance
          .loadForDomain(_domainController.text.trim());

      final config = ConfigurationService.instance.currentConfig;

      setState(() {
        _config = config;
        _status = config != null
            ? 'Configuration loaded successfully!'
            : 'Failed to load configuration';
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _status = 'Error: ${e.toString()}';
        _isLoading = false;
      });
    }
  }

  Future<void> _initializeDefault() async {
    setState(() {
      _isLoading = true;
      _status = 'Initializing default configuration...';
    });

    try {
      await ConfigurationService.instance.initialize();
      final config = ConfigurationService.instance.currentConfig;

      setState(() {
        _config = config;
        _status = 'Default configuration loaded';
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _status = 'Error: ${e.toString()}';
        _isLoading = false;
      });
    }
  }

  Future<void> _clearConfiguration() async {
    await ConfigurationService.instance.clearConfiguration();
    setState(() {
      _config = null;
      _status = 'Configuration cleared';
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Configuration System Tester'),
        backgroundColor: DynamicThemeService.instance.getColor('secondary1'),
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Test Configuration System',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'This tests the basic configuration system without smart domain resolution.',
                      style: TextStyle(color: Colors.grey),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: _domainController,
                      decoration: const InputDecoration(
                        labelText: 'Domain to test',
                        hintText: 'learn.instructohub.com',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.language),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: _isLoading ? null : _testConfiguration,
                            icon: _isLoading
                                ? const SizedBox(
                                    width: 16,
                                    height: 16,
                                    child: CircularProgressIndicator(
                                        strokeWidth: 2),
                                  )
                                : const Icon(Icons.play_arrow),
                            label:
                                Text(_isLoading ? 'Testing...' : 'Test Domain'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: DynamicThemeService.instance
                                  .getColor('secondary1'),
                              foregroundColor: Colors.white,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        ElevatedButton(
                          onPressed: _isLoading ? null : _initializeDefault,
                          child: const Text('Load Default'),
                        ),
                        const SizedBox(width: 8),
                        ElevatedButton(
                          onPressed: _clearConfiguration,
                          child: const Text('Clear'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.red,
                            foregroundColor: Colors.white,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: _status.contains('Error')
                            ? Colors.red.withOpacity(0.1)
                            : _status.contains('success') ||
                                    _status.contains('loaded')
                                ? Colors.green.withOpacity(0.1)
                                : Colors.blue.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        'Status: $_status',
                        style: TextStyle(
                          color: _status.contains('Error')
                              ? Colors.red.shade700
                              : _status.contains('success') ||
                                      _status.contains('loaded')
                                  ? Colors.green.shade700
                                  : Colors.blue.shade700,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 16),

            // Quick test domains
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Quick Test Domains',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        'learn.instructohub.com',
                        'www.university.edu',
                        'app.school.org',
                        'moodle.college.com',
                      ]
                          .map(
                            (domain) => ActionChip(
                              label: Text(domain),
                              onPressed: () {
                                _domainController.text = domain;
                                _testConfiguration();
                              },
                              backgroundColor: AppTheme.secondary3,
                            ),
                          )
                          .toList(),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 16),

            if (_config != null) _buildConfigurationDisplay(),
          ],
        ),
      ),
    );
  }

  Widget _buildConfigurationDisplay() {
    return Expanded(
      child: SingleChildScrollView(
        child: Card(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Current Configuration',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),
                _buildSection('Basic Info', [
                  _buildInfoRow('LMS Type', _config!.lmsType),
                  _buildInfoRow('Domain',
                      _config!.domain.isEmpty ? 'Default' : _config!.domain),
                  _buildInfoRow(
                      'Last Updated', _config!.lastUpdated.toString()),
                ]),
                _buildSection(
                    'API Endpoints',
                    _config!.apiEndpoints.entries
                        .map((e) => _buildInfoRow(e.key,
                            e.value.isEmpty ? 'Not configured' : e.value))
                        .toList()),
                _buildSection(
                    'API Functions (Sample)',
                    _config!.apiFunctions.entries
                        .take(5)
                        .map((e) => _buildInfoRow(e.key, e.value))
                        .toList()),
                _buildSection(
                    'Theme Colors',
                    _config!.themeColors.entries
                        .map((e) => _buildColorRow(e.key, e.value))
                        .toList()),
                _buildSection(
                    'Icon Mappings (Sample)',
                    _config!.iconMappings.entries
                        .take(5)
                        .map((e) => _buildInfoRow(e.key, e.value))
                        .toList()),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.green.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.green.withOpacity(0.3)),
                  ),
                  child: const Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '✅ Basic Configuration System Working',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.green,
                        ),
                      ),
                      SizedBox(height: 8),
                      Text(
                        'The configuration system is running alongside your existing code without breaking anything. Your app continues to work normally while gaining dynamic configuration capabilities!',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.green,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSection(String title, List<Widget> children) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: DynamicThemeService.instance.getColor('secondary1'),
          ),
        ),
        const SizedBox(height: 8),
        ...children,
        const SizedBox(height: 16),
      ],
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              '$label:',
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(color: Colors.grey.shade700),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildColorRow(String label, String colorHex) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        children: [
          SizedBox(
            width: 120,
            child: Text(
              '$label:',
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
          ),
          Container(
            width: 20,
            height: 20,
            decoration: BoxDecoration(
              color: Color(int.parse('0xFF${colorHex.replaceAll('#', '')}')),
              border: Border.all(color: Colors.grey),
              borderRadius: BorderRadius.circular(4),
            ),
          ),
          const SizedBox(width: 8),
          Text(
            colorHex,
            style: TextStyle(color: Colors.grey.shade700),
          ),
        ],
      ),
    );
  }
}
