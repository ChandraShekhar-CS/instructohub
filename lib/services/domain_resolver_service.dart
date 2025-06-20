// File: lib/services/domain_resolver_service.dart

import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class DomainResolverService {
  static DomainResolverService? _instance;
  Map<String, DomainResolutionResult> _cachedResults = {};
  
  DomainResolverService._internal();
  
  static DomainResolverService get instance {
    _instance ??= DomainResolverService._internal();
    return _instance!;
  }

  /// Main method to resolve any domain to working API endpoints
  Future<DomainResolutionResult?> resolveDomain(String inputDomain) async {
    final normalizedInput = _normalizeDomain(inputDomain);
    
    // Check memory cache first
    if (_cachedResults.containsKey(normalizedInput)) {
      final cached = _cachedResults[normalizedInput]!;
      // Use cached result if less than 24 hours old
      if (DateTime.now().difference(cached.lastTested).inHours < 24) {
        print('✅ Using memory cached result for: $normalizedInput');
        return cached;
      }
    }

    // Check persistent cache
    final cachedResult = await _loadCachedResult(normalizedInput);
    if (cachedResult != null && DateTime.now().difference(cachedResult.lastTested).inHours < 24) {
      _cachedResults[normalizedInput] = cachedResult;
      print('✅ Using persistent cached result for: $normalizedInput');
      return cachedResult;
    }

    print('🔍 Resolving domain with smart detection: $normalizedInput');
    final result = await _performDomainResolution(normalizedInput);
    
    if (result != null) {
      _cachedResults[normalizedInput] = result;
      await _saveCachedResult(normalizedInput, result);
    }
    
    return result;
  }

  String _normalizeDomain(String domain) {
    domain = domain.trim().toLowerCase();
    
    if (!domain.startsWith('http://') && !domain.startsWith('https://')) {
      domain = 'https://$domain';
    }
    
    if (domain.endsWith('/')) {
      domain = domain.substring(0, domain.length - 1);
    }
    
    return domain;
  }

  Future<DomainResolutionResult?> _performDomainResolution(String normalizedDomain) async {
    final patterns = _generateDomainPatterns(normalizedDomain);
    
    print('Testing ${patterns.length} domain patterns...');
    
    for (final pattern in patterns) {
      print('Testing: ${pattern.description}');
      
      try {
        final endpoints = _generateEndpoints(pattern.apiDomain);
        final testResult = await _testEndpoints(endpoints);
        
        if (testResult.isValid) {
          print('✅ SUCCESS: ${pattern.description}');
          
          return DomainResolutionResult(
            originalDomain: normalizedDomain,
            frontendDomain: pattern.frontendDomain,
            apiDomain: pattern.apiDomain,
            endpoints: endpoints,
            pattern: pattern,
            siteInfo: testResult.siteInfo,
            isValid: true,
            lastTested: DateTime.now(),
          );
        }
      } catch (e) {
        print('❌ FAILED: ${pattern.description} - $e');
        continue;
      }
    }
    
    print('❌ No valid patterns found for: $normalizedDomain');
    return null;
  }

  List<DomainPattern> _generateDomainPatterns(String originalDomain) {
    final uri = Uri.parse(originalDomain);
    final host = uri.host;
    final scheme = uri.scheme;
    
    final patterns = <DomainPattern>[];
    
    // 1. InstructoHub specific patterns (highest priority)
    if (host.contains('learn.instructohub.com')) {
      patterns.add(DomainPattern(
        frontendDomain: originalDomain,
        apiDomain: originalDomain.replaceAll('learn.instructohub.com', 'moodle.instructohub.com'),
        description: 'InstructoHub: learn → moodle',
        priority: 1,
        patternType: 'instructohub_specific',
      ));
    }
    
    // 2. Generic learn.* patterns
    if (host.startsWith('learn.')) {
      final baseDomain = host.substring(6); // Remove 'learn.'
      
      patterns.add(DomainPattern(
        frontendDomain: originalDomain,
        apiDomain: '$scheme://moodle.$baseDomain',
        description: 'Generic: learn.* → moodle.*',
        priority: 2,
        patternType: 'learn_to_moodle',
      ));
      
      patterns.add(DomainPattern(
        frontendDomain: originalDomain,
        apiDomain: '$scheme://api.$baseDomain',
        description: 'Generic: learn.* → api.*',
        priority: 3,
        patternType: 'learn_to_api',
      ));
      
      patterns.add(DomainPattern(
        frontendDomain: originalDomain,
        apiDomain: '$scheme://lms.$baseDomain',
        description: 'Generic: learn.* → lms.*',
        priority: 4,
        patternType: 'learn_to_lms',
      ));
    }
    
    // 3. www.* patterns
    if (host.startsWith('www.')) {
      final baseDomain = host.substring(4); // Remove 'www.'
      
      patterns.add(DomainPattern(
        frontendDomain: originalDomain,
        apiDomain: '$scheme://moodle.$baseDomain',
        description: 'WWW: www.* → moodle.*',
        priority: 5,
        patternType: 'www_to_moodle',
      ));
      
      patterns.add(DomainPattern(
        frontendDomain: originalDomain,
        apiDomain: '$scheme://api.$baseDomain',
        description: 'WWW: www.* → api.*',
        priority: 6,
        patternType: 'www_to_api',
      ));
      
      patterns.add(DomainPattern(
        frontendDomain: originalDomain,
        apiDomain: '$scheme://lms.$baseDomain',
        description: 'WWW: www.* → lms.*',
        priority: 7,
        patternType: 'www_to_lms',
      ));
    }
    
    // 4. app.* patterns
    if (host.startsWith('app.')) {
      final baseDomain = host.substring(4); // Remove 'app.'
      
      patterns.add(DomainPattern(
        frontendDomain: originalDomain,
        apiDomain: '$scheme://api.$baseDomain',
        description: 'App: app.* → api.*',
        priority: 8,
        patternType: 'app_to_api',
      ));
      
      patterns.add(DomainPattern(
        frontendDomain: originalDomain,
        apiDomain: '$scheme://moodle.$baseDomain',
        description: 'App: app.* → moodle.*',
        priority: 9,
        patternType: 'app_to_moodle',
      ));
    }
    
    // 5. Subdomain injection patterns (for base domains)
    if (!host.contains('moodle') && !host.contains('api') && !host.contains('lms') && 
        !host.contains('learn') && !host.contains('www') && !host.contains('app')) {
      
      patterns.add(DomainPattern(
        frontendDomain: originalDomain,
        apiDomain: '$scheme://moodle.$host',
        description: 'Injection: domain → moodle.domain',
        priority: 10,
        patternType: 'subdomain_injection_moodle',
      ));
      
      patterns.add(DomainPattern(
        frontendDomain: originalDomain,
        apiDomain: '$scheme://api.$host',
        description: 'Injection: domain → api.domain',
        priority: 11,
        patternType: 'subdomain_injection_api',
      ));
      
      patterns.add(DomainPattern(
        frontendDomain: originalDomain,
        apiDomain: '$scheme://lms.$host',
        description: 'Injection: domain → lms.domain',
        priority: 12,
        patternType: 'subdomain_injection_lms',
      ));
    }
    
    // 6. Path-based patterns
    patterns.add(DomainPattern(
      frontendDomain: originalDomain,
      apiDomain: '$originalDomain/api',
      description: 'Path: domain/api',
      priority: 13,
      patternType: 'path_based_api',
    ));
    
    patterns.add(DomainPattern(
      frontendDomain: originalDomain,
      apiDomain: '$originalDomain/moodle',
      description: 'Path: domain/moodle',
      priority: 14,
      patternType: 'path_based_moodle',
    ));
    
    patterns.add(DomainPattern(
      frontendDomain: originalDomain,
      apiDomain: '$originalDomain/lms',
      description: 'Path: domain/lms',
      priority: 15,
      patternType: 'path_based_lms',
    ));
    
    // 7. Direct same domain (last resort)
    patterns.add(DomainPattern(
      frontendDomain: originalDomain,
      apiDomain: originalDomain,
      description: 'Direct: same domain',
      priority: 16,
      patternType: 'direct_same',
    ));
    
    // Sort by priority (lowest number = highest priority)
    patterns.sort((a, b) => a.priority.compareTo(b.priority));
    return patterns;
  }

  Map<String, String> _generateEndpoints(String apiDomain) {
    return {
      'base': '$apiDomain/webservice/rest/server.php',
      'login': '$apiDomain/login/token.php',
      'upload': '$apiDomain/webservice/upload.php',
      'api': apiDomain,
    };
  }

  Future<EndpointTestResult> _testEndpoints(Map<String, String> endpoints) async {
    try {
      final testUrl = '${endpoints['base']}?wsfunction=core_webservice_get_site_info&moodlewsrestformat=json';
      
      final response = await http.get(Uri.parse(testUrl)).timeout(
        const Duration(seconds: 8),
      );
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        
        // Check for valid Moodle/LMS responses
        final isValidLMSResponse = 
          (data['message'] != null && data['message'].toString().contains('Invalid token')) ||
          (data['errorcode'] != null) ||
          (data['exception'] != null) ||
          (data['sitename'] != null);
        
        if (isValidLMSResponse) {
          Map<String, dynamic> siteInfo = {};
          
          if (data['sitename'] != null) {
            siteInfo = {
              'sitename': data['sitename'],
              'siteurl': data['siteurl'],
              'release': data['release'],
              'version': data['version'],
            };
          } else {
            siteInfo = {
              'sitename': 'LMS Instance',
              'siteurl': endpoints['api'],
              'release': 'Detected',
              'version': 'Unknown',
            };
          }
          
          return EndpointTestResult(
            isValid: true,
            siteInfo: siteInfo,
            statusCode: response.statusCode,
            responseData: data,
          );
        }
      }
      
      return EndpointTestResult(
        isValid: false,
        statusCode: response.statusCode,
        error: 'Invalid LMS response',
        responseData: response.statusCode == 200 ? json.decode(response.body) : null,
      );
      
    } catch (e) {
      return EndpointTestResult(
        isValid: false,
        error: e.toString(),
      );
    }
  }

  Future<DomainResolutionResult?> _loadCachedResult(String domain) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final cacheKey = 'domain_resolution_${Uri.encodeComponent(domain)}';
      final cachedData = prefs.getString(cacheKey);
      
      if (cachedData != null) {
        final data = json.decode(cachedData);
        final Map<String, dynamic> convertedData = Map<String, dynamic>.from(data);
        return DomainResolutionResult.fromJson(convertedData);
      }
    } catch (e) {
      print('Error loading cached result: $e');
    }
    return null;
  }

  Future<void> _saveCachedResult(String domain, DomainResolutionResult result) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final cacheKey = 'domain_resolution_${Uri.encodeComponent(domain)}';
      await prefs.setString(cacheKey, json.encode(result.toJson()));
      print('✅ Cached resolution result for: $domain');
    } catch (e) {
      print('Error saving cached result: $e');
    }
  }

  Future<void> clearCache() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final keys = prefs.getKeys().where((key) => key.startsWith('domain_resolution_'));
      for (final key in keys) {
        await prefs.remove(key);
      }
      _cachedResults.clear();
      print('Domain resolution cache cleared');
    } catch (e) {
      print('Error clearing cache: $e');
    }
  }

  Future<List<DomainResolutionResult>> getCachedResults() async {
    final results = <DomainResolutionResult>[];
    try {
      final prefs = await SharedPreferences.getInstance();
      final keys = prefs.getKeys().where((key) => key.startsWith('domain_resolution_'));
      
      for (final key in keys) {
        final data = prefs.getString(key);
        if (data != null) {
          try {
            final jsonData = json.decode(data);
            final Map<String, dynamic> convertedData = Map<String, dynamic>.from(jsonData);
            final result = DomainResolutionResult.fromJson(convertedData);
            results.add(result);
          } catch (e) {
            print('Error parsing cached result for $key: $e');
          }
        }
      }
    } catch (e) {
      print('Error getting cached results: $e');
    }
    
    results.sort((a, b) => b.lastTested.compareTo(a.lastTested));
    return results;
  }
}

// Supporting classes
class DomainPattern {
  final String frontendDomain;
  final String apiDomain;
  final String description;
  final int priority;
  final String patternType;

  DomainPattern({
    required this.frontendDomain,
    required this.apiDomain,
    required this.description,
    required this.priority,
    required this.patternType,
  });

  Map<String, dynamic> toJson() {
    return {
      'frontendDomain': frontendDomain,
      'apiDomain': apiDomain,
      'description': description,
      'priority': priority,
      'patternType': patternType,
    };
  }

  factory DomainPattern.fromJson(Map<String, dynamic> json) {
    return DomainPattern(
      frontendDomain: json['frontendDomain']?.toString() ?? '',
      apiDomain: json['apiDomain']?.toString() ?? '',
      description: json['description']?.toString() ?? '',
      priority: json['priority'] ?? 0,
      patternType: json['patternType']?.toString() ?? '',
    );
  }
}

class EndpointTestResult {
  final bool isValid;
  final Map<String, dynamic>? siteInfo;
  final int? statusCode;
  final String? error;
  final dynamic responseData;

  EndpointTestResult({
    required this.isValid,
    this.siteInfo,
    this.statusCode,
    this.error,
    this.responseData,
  });
}

class DomainResolutionResult {
  final String originalDomain;
  final String frontendDomain;
  final String apiDomain;
  final Map<String, String> endpoints;
  final DomainPattern pattern;
  final Map<String, dynamic>? siteInfo;
  final bool isValid;
  final DateTime lastTested;

  DomainResolutionResult({
    required this.originalDomain,
    required this.frontendDomain,
    required this.apiDomain,
    required this.endpoints,
    required this.pattern,
    this.siteInfo,
    required this.isValid,
    required this.lastTested,
  });

  Map<String, dynamic> toJson() {
    return {
      'originalDomain': originalDomain,
      'frontendDomain': frontendDomain,
      'apiDomain': apiDomain,
      'endpoints': endpoints,
      'pattern': pattern.toJson(),
      'siteInfo': siteInfo,
      'isValid': isValid,
      'lastTested': lastTested.toIso8601String(),
    };
  }

  factory DomainResolutionResult.fromJson(Map<String, dynamic> json) {
    // Safe conversion for endpoints
    Map<String, String> safeEndpoints = {};
    if (json['endpoints'] != null) {
      final endpoints = json['endpoints'];
      if (endpoints is Map) {
        endpoints.forEach((key, value) {
          if (key != null && value != null) {
            safeEndpoints[key.toString()] = value.toString();
          }
        });
      }
    }

    // Safe conversion for siteInfo
    Map<String, dynamic>? safeSiteInfo;
    if (json['siteInfo'] != null && json['siteInfo'] is Map) {
      safeSiteInfo = Map<String, dynamic>.from(json['siteInfo']);
    }

    return DomainResolutionResult(
      originalDomain: json['originalDomain']?.toString() ?? '',
      frontendDomain: json['frontendDomain']?.toString() ?? '',
      apiDomain: json['apiDomain']?.toString() ?? '',
      endpoints: safeEndpoints,
      pattern: DomainPattern.fromJson(json['pattern'] ?? {}),
      siteInfo: safeSiteInfo,
      isValid: json['isValid'] ?? false,
      lastTested: DateTime.tryParse(json['lastTested']?.toString() ?? '') ?? DateTime.now(),
    );
  }

  String get displayName => siteInfo?['sitename']?.toString() ?? 'LMS Instance';
  String get version => siteInfo?['release']?.toString() ?? 'Unknown';
}