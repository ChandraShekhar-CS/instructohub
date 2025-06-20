// File: lib/services/dynamic_theme_service.dart

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import './api_service.dart';
import '../theme/dynamic_app_theme.dart';

// Assuming ConfigurationService exists and is correct
// import './configuration_service.dart'; 

class DynamicThemeService {
  static DynamicThemeService? _instance;
  ThemeData? _currentTheme;
  Map<String, Color>? _themeColors;
  Map<String, dynamic>? _themeConfig;
  bool _isLoaded = false;

  DynamicThemeService._internal();

  static DynamicThemeService get instance {
    _instance ??= DynamicThemeService._internal();
    return _instance!;
  }

  ThemeData get currentTheme => _currentTheme ?? _getDefaultTheme();
  Map<String, Color> get themeColors => _themeColors ?? _getDefaultColors();
  bool get isLoaded => _isLoaded;

  Future<void> loadTheme({String? token}) async {
    try {
      // await ConfigurationService.instance.initialize();

      Map<String, dynamic>? remoteTheme;
      if (token != null && ApiService.instance.isConfigured) {
        remoteTheme = await _fetchRemoteTheme(token);
      }

      final cachedTheme = await _loadCachedTheme();

      Map<String, dynamic> finalThemeConfig;
      if (remoteTheme != null) {
        finalThemeConfig = remoteTheme;
        await _saveCachedTheme(remoteTheme);
        print('✅ Using remote theme configuration');
      } else if (cachedTheme != null) {
        finalThemeConfig = cachedTheme;
        print('✅ Using cached theme configuration');
      } else {
        // finalThemeConfig = _getConfigurationColors();
        finalThemeConfig = _getDefaultThemeConfig();
        print('✅ Using default theme configuration');
      }

      _themeConfig = finalThemeConfig;
      _themeColors = _parseThemeColors(finalThemeConfig);
      _currentTheme = _buildDynamicTheme(_themeColors!);
      _isLoaded = true;

      print('🎨 Dynamic theme loaded successfully');
    } catch (e) {
      print('❌ Error loading dynamic theme: $e');
      _themeColors = _getDefaultColors();
      _currentTheme = _getDefaultTheme();
      _isLoaded = true;
    }
  }

  Future<Map<String, dynamic>?> _fetchRemoteTheme(String token) async {
    try {
      final response = await ApiService.instance.callCustomAPI(
        'local_instructohub_get_theme_config',
        token,
        {},
      );

      if (response != null && response is Map) {
        return Map<String, dynamic>.from(response);
      }
    } catch (e) {
      print('Failed to fetch remote theme: $e');
    }
    return null;
  }
  
  /*
  Map<String, dynamic> _getConfigurationColors() {
    final config = ConfigurationService.instance.currentConfig;
    if (config != null) {
      return {
        'colors': config.themeColors,
        'source': 'configuration_service',
        'last_updated': DateTime.now().toIso8601String(),
      };
    }
    return _getDefaultThemeConfig();
  }
  */

  Map<String, dynamic> _getDefaultThemeConfig() {
    return {
      'colors': {
        'primary1': '#1f2937',
        'primary2': '#6b7280',
        'primary3': '#000000',
        'secondary1': '#E16B3A',
        'secondary2': '#1B3943',
        'secondary3': '#FBECE6',
        'background': '#F7F7F7',
        'cardColor': '#FFFFFF',
        'textPrimary': '#1f2937',
        'textSecondary': '#6b7280',
        'success': '#10B981',
        'warning': '#F59E0B',
        'error': '#EF4444',
        'info': '#3B82F6',
      },
      'typography': {
        'fontFamily': 'Inter',
        'headlineLarge': 24.0,
        'headlineMedium': 20.0,
        'titleLarge': 18.0,
        'titleMedium': 16.0,
        'bodyLarge': 16.0,
        'bodyMedium': 14.0,
        'bodySmall': 12.0,
      },
      'spacing': {
        'xs': 4.0,
        'sm': 8.0,
        'md': 16.0,
        'lg': 24.0,
        'xl': 32.0,
      },
      'borderRadius': {
        'small': 8.0,
        'medium': 12.0,
        'large': 16.0,
        'xl': 20.0,
      },
      'elevation': {
        'low': 2.0,
        'medium': 4.0,
        'high': 8.0,
      },
      'source': 'default',
      'last_updated': DateTime.now().toIso8601String(),
    };
  }

  Map<String, Color> _parseThemeColors(Map<String, dynamic> themeConfig) {
    final colorsMap = themeConfig['colors'] ?? {};
    final Map<String, Color> parsedColors = {};

    colorsMap.forEach((key, value) {
      if (value is String) {
        try {
          Color color;
          if (value.startsWith('#')) {
            color = Color(int.parse('0xFF${value.substring(1)}'));
          } else if (value.startsWith('0x')) {
            color = Color(int.parse(value));
          } else {
            color = _getDefaultColors()[key] ?? Colors.grey;
          }
          parsedColors[key] = color;
        } catch (e) {
          print('Error parsing color $key: $value');
          parsedColors[key] = _getDefaultColors()[key] ?? Colors.grey;
        }
      }
    });

    final defaultColors = _getDefaultColors();
    defaultColors.forEach((key, defaultColor) {
      parsedColors.putIfAbsent(key, () => defaultColor);
    });

    return parsedColors;
  }

  Map<String, Color> _getDefaultColors() {
    return {
      'primary1': const Color(0xFF1f2937),
      'primary2': const Color(0xFF6b7280),
      'primary3': const Color(0xFF000000),
      'secondary1': const Color(0xFFE16B3A),
      'secondary2': const Color(0xFF1B3943),
      'secondary3': const Color(0xFFFBECE6),
      'background': const Color(0xFFF7F7F7),
      'cardColor': const Color(0xFFFFFFFF),
      'textPrimary': const Color(0xFF1f2937),
      'textSecondary': const Color(0xFF6b7280),
      'success': const Color(0xFF10B981),
      'warning': const Color(0xFFF59E0B),
      'error': const Color(0xFFEF4444),
      'info': const Color(0xFF3B82F6),
    };
  }

  ThemeData _buildDynamicTheme(Map<String, Color> colors) {
    final typography =
        _themeConfig?['typography'] as Map<String, dynamic>? ?? {};
    final spacing = _themeConfig?['spacing'] as Map<String, dynamic>? ?? {};
    final borderRadiusCfg =
        _themeConfig?['borderRadius'] as Map<String, dynamic>? ?? {};
    final elevationCfg =
        _themeConfig?['elevation'] as Map<String, dynamic>? ?? {};

    return ThemeData(
      primarySwatch: _createMaterialColor(colors['secondary1']!),
      primaryColor: colors['secondary1'],
      scaffoldBackgroundColor: colors['background'],
      fontFamily: typography['fontFamily'] as String? ?? 'Inter',
      colorScheme: ColorScheme.light(
        primary: colors['secondary1']!,
        secondary: colors['secondary2']!,
        surface: colors['cardColor']!,
        background: colors['background']!,
        error: colors['error']!,
        onPrimary: Colors.white,
        onSecondary: Colors.white,
        onSurface: colors['textPrimary']!,
        onBackground: colors['textPrimary']!,
        onError: Colors.white,
      ),

      appBarTheme: AppBarTheme(
        backgroundColor: colors['background'],
        elevation: (elevationCfg['low'] as num?)?.toDouble() ?? 2.0,
        iconTheme: IconThemeData(color: colors['textPrimary']),
        titleTextStyle: TextStyle(
          color: colors['textPrimary'],
          fontSize: (typography['titleLarge'] as num?)?.toDouble() ?? 18.0,
          fontWeight: FontWeight.bold,
          fontFamily: typography['fontFamily'] as String? ?? 'Inter',
        ),
      ),

      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: colors['secondary1'],
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(
              (borderRadiusCfg['medium'] as num?)?.toDouble() ?? 12.0,
            ),
          ),
          elevation: (elevationCfg['medium'] as num?)?.toDouble() ?? 4.0,
          textStyle: TextStyle(
            fontWeight: FontWeight.w600,
            fontFamily: typography['fontFamily'] as String? ?? 'Inter',
            fontSize: (typography['bodyLarge'] as num?)?.toDouble() ?? 16.0,
          ),
        ),
      ),

      // FIXED: The class name was corrected from CardTheme to CardThemeData
      cardTheme: CardThemeData(
        color: colors['cardColor'],
        elevation: (elevationCfg['medium'] as num?)?.toDouble() ?? 4.0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(
            (borderRadiusCfg['medium'] as num?)?.toDouble() ?? 12.0,
          ),
        ),
        shadowColor: Colors.black.withOpacity(0.1),
      ),

      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: colors['cardColor'],
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(
            (borderRadiusCfg['medium'] as num?)?.toDouble() ?? 12.0,
          ),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(
            (borderRadiusCfg['medium'] as num?)?.toDouble() ?? 12.0,
          ),
          borderSide: BorderSide(color: colors['textSecondary']!.withOpacity(0.3)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(
            (borderRadiusCfg['medium'] as num?)?.toDouble() ?? 12.0,
          ),
          borderSide: BorderSide(color: colors['secondary1']!, width: 2),
        ),
        contentPadding: EdgeInsets.symmetric(
          vertical: (spacing['md'] as num?)?.toDouble() ?? 16.0,
          horizontal: (spacing['md'] as num?)?.toDouble() ?? 16.0,
        ),
        hintStyle: TextStyle(color: colors['textSecondary']),
      ),

      textTheme: TextTheme(
        headlineLarge: TextStyle(
          color: colors['textPrimary'],
          fontWeight: FontWeight.bold,
          fontFamily: typography['fontFamily'] ?? 'Inter',
          fontSize: (typography['headlineLarge'] as num?)?.toDouble() ?? 24.0,
        ),
        headlineMedium: TextStyle(
          color: colors['textPrimary'],
          fontWeight: FontWeight.bold,
          fontFamily: typography['fontFamily'] ?? 'Inter',
          fontSize: (typography['headlineMedium'] as num?)?.toDouble() ?? 20.0,
        ),
        titleLarge: TextStyle(
          color: colors['textPrimary'],
          fontWeight: FontWeight.bold,
          fontFamily: typography['fontFamily'] as String? ?? 'Inter',
          fontSize: (typography['titleLarge'] as num?)?.toDouble() ?? 18.0,
        ),
        titleMedium: TextStyle(
          color: colors['textPrimary'],
          fontWeight: FontWeight.w600,
          fontFamily: typography['fontFamily'] as String? ?? 'Inter',
          fontSize: (typography['titleMedium'] as num?)?.toDouble() ?? 16.0,
        ),
        bodyLarge: TextStyle(
          color: colors['textPrimary'],
          fontFamily: typography['fontFamily'] as String? ?? 'Inter',
          fontSize: (typography['bodyLarge'] as num?)?.toDouble() ?? 16.0,
        ),
        bodyMedium: TextStyle(
          color: colors['textSecondary'],
          fontFamily: typography['fontFamily'] as String? ?? 'Inter',
          fontSize: (typography['bodyMedium'] as num?)?.toDouble() ?? 14.0,
        ),
      ),

      iconTheme: IconThemeData(
        color: colors['secondary1'],
      ),

      dividerTheme: DividerThemeData(
        color: colors['textSecondary']?.withOpacity(0.3),
        thickness: 1,
      ),

      checkboxTheme: CheckboxThemeData(
        fillColor: MaterialStateProperty.resolveWith((states) {
          if (states.contains(MaterialState.selected)) {
            return colors['secondary1'];
          }
          return Colors.transparent;
        }),
        checkColor: MaterialStateProperty.all(colors['cardColor']),
        side: BorderSide(color: colors['secondary1']!, width: 2),
      ),

      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: colors['secondary1'],
        foregroundColor: Colors.white,
      ),

      progressIndicatorTheme: ProgressIndicatorThemeData(
        color: colors['secondary1'],
      ),

      chipTheme: ChipThemeData(
        backgroundColor: colors['secondary3']!,
        labelStyle: TextStyle(color: colors['secondary1']),
        padding: EdgeInsets.all((spacing['sm'] as num?)?.toDouble() ?? 8.0),
      ),
    );
  }

  ThemeData _getDefaultTheme() {
    return _buildDynamicTheme(_getDefaultColors());
  }

  MaterialColor _createMaterialColor(Color color) {
    List strengths = <double>[.05];
    final swatch = <int, Color>{};
    final int r = color.red, g = color.green, b = color.blue;

    for (int i = 1; i < 10; i++) {
      strengths.add(0.1 * i);
    }
    for (var strength in strengths) {
      final double ds = 0.5 - strength;
      swatch[(strength * 1000).round()] = Color.fromRGBO(
        r + ((ds < 0 ? r : (255 - r)) * ds).round(),
        g + ((ds < 0 ? g : (255 - g)) * ds).round(),
        b + ((ds < 0 ? b : (255 - b)) * ds).round(),
        1,
      );
    }
    return MaterialColor(color.value, swatch);
  }

  Future<Map<String, dynamic>?> _loadCachedTheme() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final cachedData = prefs.getString('dynamic_theme_v2');
      if (cachedData != null) {
        return Map<String, dynamic>.from(json.decode(cachedData));
      }
    } catch (e) {
      print('Error loading cached theme: $e');
    }
    return null;
  }

  Future<void> _saveCachedTheme(Map<String, dynamic> themeConfig) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('dynamic_theme_v2', json.encode(themeConfig));
    } catch (e) {
      print('Error saving cached theme: $e');
    }
  }

  Future<void> clearThemeCache() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('dynamic_theme_v2');
      _currentTheme = null;
      _themeColors = null;
      _themeConfig = null;
      _isLoaded = false;
      print('Theme cache cleared');
    } catch (e) {
      print('Error clearing theme cache: $e');
    }
  }

  Color getColor(String colorKey) {
    return _themeColors?[colorKey] ??
        _getDefaultColors()[colorKey] ??
        Colors.grey;
  }

  double getSpacing(String spacingKey) {
    final spacing = _themeConfig?['spacing'] as Map<String, dynamic>? ?? {};
    return (spacing[spacingKey] as num?)?.toDouble() ?? 16.0;
  }

  double getBorderRadius(String radiusKey) {
    final borderRadius = _themeConfig?['borderRadius'] as Map<String, dynamic>? ?? {};
    return (borderRadius[radiusKey] as num?)?.toDouble() ?? 12.0;
  }

  double getElevation(String elevationKey) {
    final elevation = _themeConfig?['elevation'] as Map<String, dynamic>? ?? {};
    return (elevation[elevationKey] as num?)?.toDouble() ?? 4.0;
  }

  BoxDecoration getDynamicCardDecoration() {
    return BoxDecoration(
      color: getColor('cardColor'),
      borderRadius: BorderRadius.circular(getBorderRadius('medium')),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withOpacity(0.08),
          spreadRadius: 1,
          blurRadius: getElevation('medium') * 2,
          offset: const Offset(0, 2),
        ),
      ],
    );
  }

  BoxDecoration getDynamicInputDecoration() {
    return BoxDecoration(
      color: getColor('cardColor'),
      borderRadius: BorderRadius.circular(getBorderRadius('small')),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withOpacity(0.05),
          spreadRadius: 1,
          blurRadius: getElevation('low') * 2,
          offset: const Offset(0, 2),
        ),
      ],
    );
  }

  Map<String, dynamic> getThemeDebugInfo() {
    return {
      'isLoaded': _isLoaded,
      'hasThemeConfig': _themeConfig != null,
      'colorsCount': _themeColors?.length ?? 0,
      'source': _themeConfig?['source'] ?? 'unknown',
      'lastUpdated': _themeConfig?['last_updated'] ?? 'unknown',
      'sampleColors': _themeColors?.entries
              .take(5)
              .map((e) => '${e.key}: ${e.value}')
              .toList() ??
          [],
    };
  }
}
