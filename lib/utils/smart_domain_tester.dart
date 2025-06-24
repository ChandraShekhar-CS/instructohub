// File: lib/utils/smart_domain_tester.dart

import 'package:flutter/material.dart';
import '../services/configuration_service.dart';
import '../services/domain_resolver_service.dart';
import '../theme/app_theme.dart';

class SmartDomainTester extends StatefulWidget {
  const SmartDomainTester({super.key});

  @override
  State<SmartDomainTester> createState() => _SmartDomainTesterState();
}

class _SmartDomainTesterState extends State<SmartDomainTester> {
  final _domainController = TextEditingController();
  bool _isLoading = false;
  String _status = 'Ready to test smart domain resolution';
  DomainResolutionResult? _resolutionResult;
  LMSConfiguration? _config;
  List<DomainResolutionResult> _cachedDomains = [];

  // Sample domains for quick testing
  final List<String> _testDomains = [
    'learn.instructohub.com',
    'www.example-university.edu',
    'app.myschool.org',
    'learn.client.co.uk',
    'university.edu',
    'training.company.com',
  ];

  @override
  void initState() {
    super.initState();
    _loadCachedDomains();
  }

  @override
  void dispose() {
    _domainController.dispose();
    super.dispose();
  }

  Future<void> _loadCachedDomains() async {
    try {
      final cached = await ConfigurationService.instance.getCachedDomains();
      setState(() {
        _cachedDomains = cached;
      });
    } catch (e) {
      print('Error loading cached domains: $e');
    }
  }

  Future<void> _testSmartResolution(String domain) async {
    setState(() {
      _isLoading = true;
      _status = 'Running smart domain resolution...';
      _resolutionResult = null;
      _config = null;
    });

    try {
      // Initialize services
      await ConfigurationService.instance.initialize();

      // Test smart domain resolution
      final result = await DomainResolverService.instance.resolveDomain(domain);

      if (result != null) {
        // Load full configuration
        await ConfigurationService.instance.loadForDomain(domain);
        final config = ConfigurationService.instance.currentConfig;

        setState(() {
          _resolutionResult = result;
          _config = config;
          _status = result.isValid
              ? '✅ Smart resolution successful!'
              : '❌ No valid patterns found';
          _isLoading = false;
        });
      } else {
        setState(() {
          _status = '❌ Smart resolution failed - no valid endpoints found';
          _isLoading = false;
        });
      }

      // Refresh cached domains
      await _loadCachedDomains();
    } catch (e) {
      setState(() {
        _status = '❌ Error: ${e.toString()}';
        _isLoading = false;
      });
    }
  }

  Future<void> _clearCache() async {
    await DomainResolverService.instance.clearCache();
    await ConfigurationService.instance.clearConfiguration();
    await _loadCachedDomains();

    setState(() {
      _cachedDomains = [];
      _status = 'Cache cleared successfully';
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('All caches cleared successfully'),
        backgroundColor: Colors.green,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Smart Domain Resolver'),
        backgroundColor: DynamicThemeService.instance.getColor('secondary1'),
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            onPressed: _clearCache,
            icon: const Icon(Icons.clear_all),
            tooltip: 'Clear Cache',
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildTestSection(),
            const SizedBox(height: 16),
            _buildQuickTestSection(),
            const SizedBox(height: 16),
            if (_resolutionResult != null) _buildResolutionResults(),
            const SizedBox(height: 16),
            if (_config != null) _buildConfigurationResults(),
            const SizedBox(height: 16),
            _buildCachedDomainsSection(),
          ],
        ),
      ),
    );
  }

  Widget _buildTestSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '🚀 Smart Domain Resolution',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Tests 16 different domain patterns automatically to find working API endpoints.',
              style: TextStyle(color: Colors.grey),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _domainController,
              decoration: const InputDecoration(
                labelText: 'Domain to test',
                hintText: 'learn.yourschool.com',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.language),
              ),
              onSubmitted: (value) => _testSmartResolution(value),
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: _isLoading
                  ? null
                  : () => _testSmartResolution(_domainController.text),
              icon: _isLoading
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.search),
              label: Text(_isLoading ? 'Testing...' : 'Run Smart Resolution'),
              style: ElevatedButton.styleFrom(
                backgroundColor:
                    DynamicThemeService.instance.getColor('secondary1'),
                foregroundColor: Colors.white,
                minimumSize: const Size(double.infinity, 48),
              ),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: _status.contains('❌')
                    ? Colors.red.withOpacity(0.1)
                    : _status.contains('✅')
                        ? Colors.green.withOpacity(0.1)
                        : Colors.blue.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                _status,
                style: TextStyle(
                  color: _status.contains('❌')
                      ? Colors.red.shade700
                      : _status.contains('✅')
                          ? Colors.green.shade700
                          : Colors.blue.shade700,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickTestSection() {
    return Card(
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
              children: _testDomains
                  .map(
                    (domain) => ActionChip(
                      label: Text(domain),
                      onPressed: () {
                        _domainController.text = domain;
                        _testSmartResolution(domain);
                      },
                      backgroundColor: AppTheme.secondary3,
                    ),
                  )
                  .toList(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildResolutionResults() {
    final result = _resolutionResult!;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  result.isValid ? Icons.check_circle : Icons.error,
                  color: result.isValid ? Colors.green : Colors.red,
                ),
                const SizedBox(width: 8),
                Text(
                  'Smart Resolution Result',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: result.isValid
                        ? Colors.green.shade700
                        : Colors.red.shade700,
                  ),
                ),
              ],
            ),
            if (result.isValid) ...[
              const SizedBox(height: 16),
              _buildInfoSection('🎯 Pattern Used', [
                _buildInfoRow('Type', result.pattern.patternType),
                _buildInfoRow('Description', result.pattern.description),
                _buildInfoRow('Priority', '#${result.pattern.priority}'),
              ]),
              _buildInfoSection('🔄 Domain Transformation', [
                _buildInfoRow('Original', result.originalDomain),
                _buildInfoRow('Frontend', result.frontendDomain),
                _buildInfoRow('API Domain', result.apiDomain),
              ]),
              _buildInfoSection(
                  '🌐 Detected Endpoints',
                  result.endpoints.entries
                      .map((e) => _buildInfoRow(
                          e.key.toUpperCase(), _shortenUrl(e.value)))
                      .toList()),
              if (result.siteInfo != null)
                _buildInfoSection(
                    'ℹ️ LMS Information',
                    result.siteInfo!.entries
                        .map((e) =>
                            _buildInfoRow(e.key, e.value?.toString() ?? 'N/A'))
                        .toList()),
              _buildInfoSection('⚡ Performance', [
                _buildInfoRow('Cached For', '24 hours'),
                _buildInfoRow('Test Status', 'Valid LMS detected'),
              ]),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildConfigurationResults() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '⚙️ Generated Configuration',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: DynamicThemeService.instance.getColor('secondary1'),
              ),
            ),
            const SizedBox(height: 16),
            _buildInfoSection(
                'API Functions (Sample)',
                _config!.apiFunctions.entries
                    .take(5)
                    .map((e) => _buildInfoRow(e.key, e.value))
                    .toList()),
            _buildInfoSection(
                'Theme Colors',
                _config!.themeColors.entries
                    .take(4)
                    .map((e) => _buildColorRow(e.key, e.value))
                    .toList()),
            if (_config!.resolutionResult != null) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.green.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.check_circle, color: Colors.green, size: 20),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        '✨ Enhanced: Configuration includes smart domain resolution data for advanced functionality.',
                        style: TextStyle(
                          color: Colors.green,
                          fontSize: 14,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildCachedDomainsSection() {
    if (_cachedDomains.isEmpty) return const SizedBox.shrink();

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Text(
                  '📚 Cached Domains',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: DynamicThemeService.instance
                        .getColor('secondary1')
                        .withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '${_cachedDomains.length} cached',
                    style: const TextStyle(
                      color:
                          DynamicThemeService.instance.getColor('secondary1'),
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            ...(_cachedDomains.take(5).map((cached) => Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  child: ListTile(
                    leading: Icon(
                      cached.isValid ? Icons.check_circle : Icons.error,
                      color: cached.isValid ? Colors.green : Colors.red,
                      size: 20,
                    ),
                    title: Text(
                      cached.displayName,
                      style: const TextStyle(fontWeight: FontWeight.w500),
                    ),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(_shortenUrl(cached.originalDomain)),
                        Text(
                          '${cached.pattern.description} • ${DateTime.now().difference(cached.lastTested).inHours}h ago',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey.shade600,
                          ),
                        ),
                      ],
                    ),
                    trailing: const Icon(Icons.play_arrow, size: 20),
                    onTap: () {
                      _domainController.text = cached.originalDomain;
                      _testSmartResolution(cached.originalDomain);
                    },
                    tileColor: Colors.grey.shade50,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ))),
            if (_cachedDomains.length > 5) ...[
              const SizedBox(height: 8),
              Center(
                child: Text(
                  '... and ${_cachedDomains.length - 5} more',
                  style: TextStyle(
                    color: Colors.grey.shade600,
                    fontSize: 12,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildInfoSection(String title, List<Widget> children) {
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
            width: 100,
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
            width: 100,
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

  String _shortenUrl(String url) {
    if (url.length <= 40) return url;
    return '${url.substring(0, 20)}...${url.substring(url.length - 17)}';
  }
}
