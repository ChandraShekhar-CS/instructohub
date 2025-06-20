// File: lib/services/configuration_service.dart (Enhanced with Smart Resolver)
// REPLACE your existing configuration_service.dart with this

import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'domain_resolver_service.dart';

class ConfigurationService {
  static ConfigurationService? _instance;
  LMSConfiguration? _currentConfig;
  bool _isLoaded = false;

  ConfigurationService._internal();

  static ConfigurationService get instance {
    _instance ??= ConfigurationService._internal();
    return _instance!;
  }

  bool get isConfigured => _currentConfig != null;
  LMSConfiguration? get currentConfig => _currentConfig;

  // Initialize with default configuration
  Future<void> initialize() async {
    if (_isLoaded) return;
    
    try {
      // Try to load from cache first
      final cachedConfig = await _loadFromCache();
      if (cachedConfig != null) {
        _currentConfig = cachedConfig;
        print('✅ Configuration loaded from cache');
      } else {
        // Create default configuration
        _currentConfig = LMSConfiguration.createDefault();
        print('✅ Using default configuration');
      }
      
      _isLoaded = true;
    } catch (e) {
      print('⚠️ Error loading configuration: $e');
      _currentConfig = LMSConfiguration.createDefault();
      _isLoaded = true;
    }
  }

  // Enhanced domain loading with smart resolver
  Future<void> loadForDomain(String domain, {String? token}) async {
    try {
      print('🔍 Smart loading configuration for domain: $domain');
      
      // Use smart domain resolver
      final resolutionResult = await DomainResolverService.instance.resolveDomain(domain);
      
      if (resolutionResult == null || !resolutionResult.isValid) {
        print('❌ Smart domain resolution failed, using basic fallback');
        // Fallback to basic configuration
        final config = LMSConfiguration.fromDomain(domain);
        _currentConfig = config;
        await _saveToCache(config);
        return;
      }

      print('✅ Smart domain resolution successful');
      print('   Frontend: ${resolutionResult.frontendDomain}');
      print('   API: ${resolutionResult.apiDomain}');
      print('   Pattern: ${resolutionResult.pattern.description}');

      // Create configuration from resolution result
      LMSConfiguration config = LMSConfiguration.fromDomainResolution(resolutionResult);

      // Try to fetch remote configuration if token provided
      if (token != null && resolutionResult.endpoints['base']?.isNotEmpty == true) {
        print('🔄 Fetching remote configuration...');
        final remoteConfig = await _fetchRemoteConfiguration(resolutionResult.endpoints['base']!, token);
        if (remoteConfig != null) {
          print('✅ Remote configuration merged');
          config.mergeWith(remoteConfig);
        } else {
          print('ℹ️ No remote configuration available');
        }
      }

      _currentConfig = config;
      await _saveToCache(config);
      print('✅ Enhanced configuration saved');
      
    } catch (e) {
      print('❌ Error in enhanced domain loading: $e');
      // Fallback to basic configuration
      try {
        final config = LMSConfiguration.fromDomain(domain);
        _currentConfig = config;
        await _saveToCache(config);
      } catch (fallbackError) {
        print('❌ Fallback also failed: $fallbackError');
        _currentConfig = LMSConfiguration.createDefault();
      }
    }
  }

  Future<LMSConfiguration?> _fetchRemoteConfiguration(String baseUrl, String token) async {
    try {
      final url = '$baseUrl?wsfunction=local_instructohub_get_app_config&moodlewsrestformat=json&wstoken=$token';
      final response = await http.post(Uri.parse(url)).timeout(const Duration(seconds: 10));
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data != null && data is Map && !data.containsKey('exception')) {
          // Convert Map<dynamic, dynamic> to Map<String, dynamic>
          final Map<String, dynamic> convertedData = Map<String, dynamic>.from(data);
          return LMSConfiguration.fromRemoteConfig(convertedData);
        }
      }
    } catch (e) {
      print('Failed to fetch remote configuration: $e');
    }
    return null;
  }

  Future<LMSConfiguration?> _loadFromCache() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final configString = prefs.getString('lms_configuration_v4'); // Updated cache key
      if (configString != null) {
        final data = json.decode(configString);
        // Convert Map<dynamic, dynamic> to Map<String, dynamic>
        final Map<String, dynamic> configData = Map<String, dynamic>.from(data);
        return LMSConfiguration.fromJson(configData);
      }
    } catch (e) {
      print('Error loading cached configuration: $e');
    }
    return null;
  }

  Future<void> _saveToCache(LMSConfiguration config) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('lms_configuration_v4', json.encode(config.toJson()));
    } catch (e) {
      print('Error saving configuration to cache: $e');
    }
  }

  // Helper methods for easy access
  String getAPIFunction(String functionKey) {
    return _currentConfig?.apiFunctions[functionKey] ?? functionKey;
  }

  String? getEndpoint(String type) {
    return _currentConfig?.apiEndpoints[type];
  }

  Map<String, String> get themeColors => _currentConfig?.themeColors ?? {};
  Map<String, String> get iconMappings => _currentConfig?.iconMappings ?? {};
  
  // Access to domain resolution result
  DomainResolutionResult? get resolutionResult => _currentConfig?.resolutionResult;

  Future<void> clearConfiguration() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('lms_configuration_v4');
      await DomainResolverService.instance.clearCache();
      _currentConfig = LMSConfiguration.createDefault();
      _isLoaded = false;
    } catch (e) {
      print('Error clearing configuration: $e');
    }
  }

  // Get cached domain results
  Future<List<DomainResolutionResult>> getCachedDomains() async {
    return await DomainResolverService.instance.getCachedResults();
  }
}

// Enhanced LMSConfiguration class with resolution result support
class LMSConfiguration {
  final String lmsType;
  final String domain;
  final Map<String, String> apiEndpoints;
  final Map<String, String> apiFunctions;
  final Map<String, String> themeColors;
  final Map<String, String> iconMappings;
  final DateTime lastUpdated;
  final DomainResolutionResult? resolutionResult; // Now supported

  LMSConfiguration({
    required this.lmsType,
    required this.domain,
    required this.apiEndpoints,
    required this.apiFunctions,
    required this.themeColors,
    required this.iconMappings,
    required this.lastUpdated,
    this.resolutionResult,
  });

  // Create default configuration (matches your current hard-coded values)
  factory LMSConfiguration.createDefault() {
    return LMSConfiguration(
      lmsType: 'moodle',
      domain: '',
      apiEndpoints: {
        'base': '',
        'login': '',
        'upload': '',
      },
      apiFunctions: {
        'get_site_info': 'core_webservice_get_site_info',
        'get_user_courses': 'core_enrol_get_users_courses',
        'get_course_contents': 'core_course_get_contents',
        'get_page_content': 'mod_page_get_pages_by_courses',
        'get_assignments': 'mod_assign_get_assignments',
        'get_forums': 'mod_forum_get_forums_by_courses',
        'get_quizzes': 'mod_quiz_get_quizzes_by_courses',
        'get_resources': 'mod_resource_get_resources_by_courses',
        'get_enrolled_users': 'core_enrol_get_enrolled_users',
        'get_upcoming_events': 'core_calendar_get_calendar_upcoming_view',
        'get_categories': 'core_course_get_categories',
        'get_user_progress': 'local_instructohub_get_user_course_progress',
        'get_icon_config': 'local_instructohub_get_icon_config',
        'get_app_config': 'local_instructohub_get_app_config',
      },
      themeColors: {
        'primary1': '#1f2937',
        'primary2': '#6b7280',
        'secondary1': '#E16B3A',
        'secondary2': '#1B3943',
        'secondary3': '#FBECE6',
        'background': '#F7F7F7',
        'cardColor': '#FFFFFF',
      },
      iconMappings: {
        'home': 'home_outlined',
        'dashboard': 'dashboard_outlined',
        'courses': 'book_outlined',
        'settings': 'settings',
        'person': 'person_outline',
        'logout': 'logout',
        'search': 'search',
        'play': 'play_circle_outline',
        'star': 'star_border_outlined',
        'chart': 'show_chart_outlined',
        'event': 'event_outlined',
        'history': 'history_outlined',
        'bolt': 'bolt_outlined',
      },
      lastUpdated: DateTime.now(),
    );
  }

  // Create configuration from domain resolution result
  factory LMSConfiguration.fromDomainResolution(DomainResolutionResult result) {
    final defaultConfig = LMSConfiguration.createDefault();
    return LMSConfiguration(
      lmsType: defaultConfig.lmsType,
      domain: result.frontendDomain,
      apiEndpoints: result.endpoints,
      apiFunctions: defaultConfig.apiFunctions,
      themeColors: defaultConfig.themeColors,
      iconMappings: defaultConfig.iconMappings,
      lastUpdated: DateTime.now(),
      resolutionResult: result,
    );
  }

  // Create configuration from domain (basic domain-to-API mapping)
  factory LMSConfiguration.fromDomain(String domain) {
    // Normalize domain
    if (!domain.startsWith('http://') && !domain.startsWith('https://')) {
      domain = 'https://$domain';
    }
    if (domain.endsWith('/')) {
      domain = domain.substring(0, domain.length - 1);
    }

    // Simple domain transformation (like your existing logic)
    String apiDomain = domain;
    if (domain.contains('learn.instructohub.com')) {
      apiDomain = domain.replaceAll('learn.instructohub.com', 'moodle.instructohub.com');
    } else if (domain.contains('//learn.')) {
      apiDomain = domain.replaceAll('//learn.', '//moodle.');
    } else if (domain.contains('//www.')) {
      apiDomain = domain.replaceAll('//www.', '//moodle.');
    }

    final defaultConfig = LMSConfiguration.createDefault();
    return LMSConfiguration(
      lmsType: defaultConfig.lmsType,
      domain: domain,
      apiEndpoints: {
        'base': '$apiDomain/webservice/rest/server.php',
        'login': '$apiDomain/login/token.php',
        'upload': '$apiDomain/webservice/upload.php',
        'api': apiDomain,
      },
      apiFunctions: defaultConfig.apiFunctions,
      themeColors: defaultConfig.themeColors,
      iconMappings: defaultConfig.iconMappings,
      lastUpdated: DateTime.now(),
    );
  }

  factory LMSConfiguration.fromJson(Map<String, dynamic> json) {
    // Helper function to safely convert maps
    Map<String, String> safeStringMap(dynamic input, Map<String, String> fallback) {
      if (input == null) return fallback;
      if (input is Map) {
        final result = <String, String>{};
        input.forEach((key, value) {
          if (key != null && value != null) {
            result[key.toString()] = value.toString();
          }
        });
        return result.isEmpty ? fallback : result;
      }
      return fallback;
    }

    final defaultConfig = LMSConfiguration.createDefault();
    
    // Handle resolution result
    DomainResolutionResult? resolutionResult;
    if (json['resolutionResult'] != null && json['resolutionResult'] is Map) {
      try {
        final resultData = Map<String, dynamic>.from(json['resolutionResult']);
        resolutionResult = DomainResolutionResult.fromJson(resultData);
      } catch (e) {
        print('Error parsing resolution result: $e');
      }
    }
    
    return LMSConfiguration(
      lmsType: json['lmsType']?.toString() ?? 'moodle',
      domain: json['domain']?.toString() ?? '',
      apiEndpoints: safeStringMap(json['apiEndpoints'], defaultConfig.apiEndpoints),
      apiFunctions: safeStringMap(json['apiFunctions'], defaultConfig.apiFunctions),
      themeColors: safeStringMap(json['themeColors'], defaultConfig.themeColors),
      iconMappings: safeStringMap(json['iconMappings'], defaultConfig.iconMappings),
      lastUpdated: DateTime.tryParse(json['lastUpdated']?.toString() ?? '') ?? DateTime.now(),
      resolutionResult: resolutionResult,
    );
  }

  factory LMSConfiguration.fromRemoteConfig(Map<String, dynamic> remoteData) {
    final defaultConfig = LMSConfiguration.createDefault();
    
    // Safely convert nested maps
    Map<String, String> safeStringMap(dynamic input, Map<String, String> fallback) {
      if (input == null) return fallback;
      if (input is Map) {
        final result = <String, String>{};
        input.forEach((key, value) {
          if (key != null && value != null) {
            result[key.toString()] = value.toString();
          }
        });
        return result.isEmpty ? fallback : result;
      }
      return fallback;
    }
    
    return LMSConfiguration(
      lmsType: remoteData['lms_type']?.toString() ?? defaultConfig.lmsType,
      domain: remoteData['domain']?.toString() ?? defaultConfig.domain,
      apiEndpoints: safeStringMap(remoteData['api_endpoints'], defaultConfig.apiEndpoints),
      apiFunctions: safeStringMap(remoteData['api_functions'], defaultConfig.apiFunctions),
      themeColors: safeStringMap(remoteData['theme_colors'], defaultConfig.themeColors),
      iconMappings: safeStringMap(remoteData['icon_mappings'], defaultConfig.iconMappings),
      lastUpdated: DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'lmsType': lmsType,
      'domain': domain,
      'apiEndpoints': apiEndpoints,
      'apiFunctions': apiFunctions,
      'themeColors': themeColors,
      'iconMappings': iconMappings,
      'lastUpdated': lastUpdated.toIso8601String(),
      'resolutionResult': resolutionResult?.toJson(),
    };
  }

  void mergeWith(LMSConfiguration other) {
    apiFunctions.addAll(other.apiFunctions);
    themeColors.addAll(other.themeColors);
    iconMappings.addAll(other.iconMappings);
    if (other.apiEndpoints.isNotEmpty) {
      apiEndpoints.addAll(other.apiEndpoints);
    }
  }
}