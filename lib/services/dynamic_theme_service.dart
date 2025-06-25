import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:InstructoHub/services/api_service.dart';

class DynamicThemeService {
  static DynamicThemeService? _instance;
  ThemeData? _currentTheme;
  Map<String, Color>? _themeColors;
  Map<String, dynamic>? _themeConfig;
  bool _isLoaded = false;

  String? _logoUrl;
  String? _siteName;
  String? _loginLeftBgUrl;
  String? _loginRightBgUrl;

  DynamicThemeService._internal();

  static DynamicThemeService get instance {
    _instance ??= DynamicThemeService._internal();
    return _instance!;
  }

  ThemeData get currentTheme => _currentTheme ?? _buildDynamicTheme(_getDefaultColors());
  Map<String, Color> get themeColors => _themeColors ?? _getDefaultColors();
  bool get isLoaded => _isLoaded;
  String? get logoUrl => _logoUrl;
  String? get siteName => _siteName;
  String? get loginLeftBgUrl => _loginLeftBgUrl;
  String? get loginRightBgUrl => _loginRightBgUrl;

  Future<void> loadTheme({String? token}) async {
    try {
      Map<String, dynamic>? remoteTheme;
      String? fetchedSiteName;
      String? fetchedLogoUrl;

      if (ApiService.instance.isConfigured) {
        remoteTheme = await _fetchAndProcessRemoteTheme();

        try {
          final siteInfo = await ApiService.instance.callCustomAPI('core_webservice_get_site_info', token ?? '', {});
          if (siteInfo != null && siteInfo['sitename'] != null) {
            fetchedSiteName = siteInfo['sitename'];
            fetchedLogoUrl = remoteTheme?['imageUrls']?['logo_image'] ?? siteInfo['userpictureurl'];
          }
        } catch (e) {
          print('Could not fetch site name, will use fallback. Error: $e');
        }
      }
      
      final cachedTheme = await _loadCachedTheme();
      Map<String, dynamic> finalThemeConfig;

      if (remoteTheme != null && _isValidThemeConfig(remoteTheme)) {
        finalThemeConfig = remoteTheme;
        finalThemeConfig['siteName'] = fetchedSiteName ?? ApiService.instance.tenantName.toUpperCase();
        finalThemeConfig['logoUrl'] = fetchedLogoUrl ?? finalThemeConfig['imageUrls']?['logo_image'];
        await _saveCachedTheme(finalThemeConfig);
        print('✅ Using remote theme configuration.');
      } else if (cachedTheme != null && _isValidThemeConfig(cachedTheme)) {
        finalThemeConfig = cachedTheme;
        print('✅ Using cached theme configuration.');
      } else {
        finalThemeConfig = _getDefaultThemeConfig();
        finalThemeConfig['siteName'] = fetchedSiteName ?? 'InstructoHub';
        print('⚠️ Using default theme configuration.');
      }
      
      _applyThemeConfig(finalThemeConfig);
      _isLoaded = true;
      print('🎨 Dynamic theme and branding loaded successfully.');
    } catch (e) {
      print('❌ CRITICAL: Error loading dynamic theme: $e');
      _loadDefaultTheme();
    }
  }

  void _applyThemeConfig(Map<String, dynamic> config) {
    _themeConfig = config;
    _themeColors = _parseThemeColors(config);
    _currentTheme = _buildDynamicTheme(_themeColors!);

    _siteName = config['siteName'];
    _logoUrl = config['logoUrl'] ?? config['imageUrls']?['logo_image'];
    final imageUrls = config['imageUrls'] as Map<String, dynamic>? ?? {};
    _loginLeftBgUrl = imageUrls['login_left_bg_image'];
    _loginRightBgUrl = imageUrls['login_right_bg_image'];
  }

  void _loadDefaultTheme() {
    final defaultConfig = _getDefaultThemeConfig();
    defaultConfig['siteName'] = 'InstructoHub';
    _applyThemeConfig(defaultConfig);
    _isLoaded = true;
  }
  
  Future<Map<String, dynamic>?> _fetchAndProcessRemoteTheme() async {
    const String apiUrl = 'https://learn.mdl.instructohub.com/local/instructohub/theme.php';
    try {
      final response = await http.get(Uri.parse(apiUrl));

      if (response.statusCode == 200) {
        final apiResponse = json.decode(response.body);
        final List<dynamic> themes = apiResponse['themes'];

        final activeThemeData = themes.firstWhere(
          (t) => t['active_theme'] == 1,
          orElse: () => null,
        );

        if (activeThemeData == null) {
          print('API WARNING: No active theme found in the response.');
          return null;
        }

        final String themeDataString = activeThemeData['theme_data'];
        final Map<String, dynamic> themeDataJson = json.decode(themeDataString);
        final Map<String, dynamic> apiColors = themeDataJson['colors'] ?? {};
        final remappedColors = _remapApiColors(apiColors);

        final defaultConfig = _getDefaultThemeConfig();
        return {
          ...defaultConfig,
          'colors': remappedColors,
          'imageUrls': {
            'logo_image': activeThemeData['logo_image'],
            'login_left_bg_image': activeThemeData['login_left_bg_image'],
            'login_right_bg_image': activeThemeData['login_right_bg_image'],
          },
          'source': 'remote',
          'last_updated': DateTime.now().toIso8601String(),
        };
      } else {
        print('API ERROR: Failed to fetch theme. Status code: ${response.statusCode}');
      }
    } catch (e) {
      print('❌ Exception during theme fetch or processing: $e');
    }
    return null;
  }
  
  Map<String, String> _remapApiColors(Map<String, dynamic> apiColors) {
    String? getApiColor(String key) => apiColors[key] is String ? apiColors[key] : null;

    final defaultColors = _getDefaultThemeConfig()['colors'] as Map<String, String>;
    
    return {
      'primary': getApiColor('secondary1') ?? defaultColors['primary']!,
      'primaryVariant': getApiColor('secondary2') ?? defaultColors['primaryVariant']!,
      'secondary': getApiColor('secondary3') ?? defaultColors['secondary']!,
      'surface': getApiColor('offwhite') ?? defaultColors['surface']!,
      'background': getApiColor('navbg') ?? defaultColors['background']!,
      'onPrimary': getApiColor('loginButtonTextColor') ?? getApiColor('btnText') ?? defaultColors['onPrimary']!,
      'onSurface': getApiColor('primary1') ?? defaultColors['onSurface']!,
      'onBackground': getApiColor('primary1') ?? defaultColors['onBackground']!,
      'textPrimary': getApiColor('primary1') ?? defaultColors['textPrimary']!,
      'textSecondary': getApiColor('primary2') ?? defaultColors['textSecondary']!,
      'success': '#10B981',
      'warning': '#F59E0B',
      'error': '#EF4444',
      'info': '#3B82F6',
      'cardElevated': '#FFFFFF',
      'divider': getApiColor('primary2') ?? defaultColors['divider']!,
      'loginBgLeft': getApiColor('loginBgLeft') ?? defaultColors['loginBgLeft']!,
      'loginBgRight': getApiColor('loginBgRight') ?? defaultColors['loginBgRight']!,
      'loginTextTitle': getApiColor('loginTextTitle') ?? defaultColors['loginTextTitle']!,
      'loginTextBody': getApiColor('loginTextBody') ?? defaultColors['loginTextBody']!,
      'loginTextLink': getApiColor('loginTextLink') ?? defaultColors['loginTextLink']!,
    };
  }

  bool _isValidThemeConfig(Map<String, dynamic> config) {
    return config.containsKey('colors') &&
           config['colors'] is Map &&
           (config['colors'] as Map).isNotEmpty;
  }
  
  Future<void> _saveCachedTheme(Map<String, dynamic> themeConfig) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('dynamic_theme_v6', json.encode(themeConfig));
    } catch (e) {
      print('Error saving cached theme: $e');
    }
  }

  Future<Map<String, dynamic>?> _loadCachedTheme() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final cachedData = prefs.getString('dynamic_theme_v6');
      if (cachedData != null) {
        return Map<String, dynamic>.from(json.decode(cachedData));
      }
    } catch (e) {
      print('Error loading cached theme: $e');
    }
    return null;
  }
  
  Future<void> clearThemeCache() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('dynamic_theme_v6');
      print('Theme cache cleared.');
      forceReload();
    } catch (e) {
      print('Error clearing theme cache: $e');
    }
  }
  
  void forceReload() {
    _isLoaded = false;
    _currentTheme = null;
    _themeColors = null;
    _themeConfig = null;
    _siteName = null;
    _logoUrl = null;
  }

  Map<String, Color> _parseThemeColors(Map<String, dynamic> themeConfig) {
    final colorsMap = themeConfig['colors'] ?? {};
    final Map<String, Color> parsedColors = {};
    final defaultColorValues = _getDefaultColors();

    colorsMap.forEach((key, value) {
      if (value is String) {
        try {
          if (value.startsWith('#')) {
            parsedColors[key] = Color(int.parse('0xFF${value.substring(1)}'));
          } else {
            parsedColors[key] = defaultColorValues[key] ?? defaultColorValues['textSecondary']!;
          }
        } catch (e) {
          print('Error parsing color $key: $value. Using default.');
          parsedColors[key] = defaultColorValues[key] ?? defaultColorValues['textSecondary']!;
        }
      }
    });

    defaultColorValues.forEach((key, defaultColor) {
      parsedColors.putIfAbsent(key, () => defaultColor);
    });

    return parsedColors;
  }

  ThemeData _buildDynamicTheme(Map<String, Color> colors) {
    final typography = _themeConfig?['typography'] as Map<String, dynamic>? ?? {};
    final spacing = _themeConfig?['spacing'] as Map<String, dynamic>? ?? {};
    final borderRadiusCfg = _themeConfig?['borderRadius'] as Map<String, dynamic>? ?? {};
    final elevationCfg = _themeConfig?['elevation'] as Map<String, dynamic>? ?? {};

    return ThemeData(
      useMaterial3: true,
      primarySwatch: _createMaterialColor(colors['primary']!),
      fontFamily: typography['fontFamily'] as String? ?? 'Inter',
      
      colorScheme: ColorScheme.light(
        brightness: Brightness.light,
        primary: colors['primary']!,
        onPrimary: colors['onPrimary']!,
        primaryContainer: colors['primary']!.withOpacity(0.1),
        onPrimaryContainer: colors['primary']!,
        secondary: colors['secondary']!,
        onSecondary: colors['onPrimary']!,
        secondaryContainer: colors['secondary']!.withOpacity(0.1),
        onSecondaryContainer: colors['primary']!,
        tertiary: colors['info']!,
        onTertiary: colors['onPrimary']!,
        error: colors['error']!,
        onError: colors['onPrimary']!,
        errorContainer: colors['error']!.withOpacity(0.1),
        onErrorContainer: colors['error']!,
        background: colors['background']!,
        onBackground: colors['onBackground']!,
        surface: colors['surface']!,
        onSurface: colors['onSurface']!,
        surfaceVariant: colors['cardElevated']!,
        onSurfaceVariant: colors['textSecondary']!,
        outline: colors['divider']!.withOpacity(0.3),
        outlineVariant: colors['divider']!.withOpacity(0.1),
        shadow: Colors.black.withOpacity(0.1),
        scrim: Colors.black.withOpacity(0.5),
        inverseSurface: colors['primaryVariant']!,
        onInverseSurface: colors['onPrimary']!,
        inversePrimary: colors['onPrimary']!,
        surfaceTint: colors['primary']!,
      ),

      scaffoldBackgroundColor: colors['background'],

      appBarTheme: AppBarTheme(
        backgroundColor: colors['surface'],
        surfaceTintColor: Colors.transparent,
        elevation: (elevationCfg['low'] as num?)?.toDouble() ?? 0.0,
        scrolledUnderElevation: 4.0,
        shadowColor: colors['textPrimary']!.withOpacity(0.1),
        iconTheme: IconThemeData(color: colors['textPrimary'], size: 24),
        actionsIconTheme: IconThemeData(color: colors['textPrimary'], size: 24),
        titleTextStyle: TextStyle(
          color: colors['textPrimary'],
          fontSize: (typography['titleLarge'] as num?)?.toDouble() ?? 20.0,
          fontWeight: FontWeight.w600,
          fontFamily: typography['fontFamily'] as String? ?? 'Inter',
        ),
        centerTitle: false,
        titleSpacing: 16.0,
      ),

      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: colors['primary'],
          foregroundColor: colors['onPrimary'],
          disabledBackgroundColor: colors['textSecondary']!.withOpacity(0.3),
          disabledForegroundColor: colors['textSecondary'],
          elevation: (elevationCfg['medium'] as num?)?.toDouble() ?? 2.0,
          shadowColor: colors['primary']!.withOpacity(0.3),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular((borderRadiusCfg['medium'] as num?)?.toDouble() ?? 12.0),
          ),
          padding: EdgeInsets.symmetric(
            horizontal: (spacing['lg'] as num?)?.toDouble() ?? 24.0,
            vertical: (spacing['md'] as num?)?.toDouble() ?? 16.0,
          ),
          textStyle: TextStyle(
            fontWeight: FontWeight.w600,
            fontFamily: typography['fontFamily'] as String? ?? 'Inter',
            fontSize: (typography['bodyLarge'] as num?)?.toDouble() ?? 16.0,
          ),
        ),
      ),

      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: colors['primary'],
          side: BorderSide(color: colors['primary']!, width: 1.5),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular((borderRadiusCfg['medium'] as num?)?.toDouble() ?? 12.0),
          ),
          padding: EdgeInsets.symmetric(
            horizontal: (spacing['lg'] as num?)?.toDouble() ?? 24.0,
            vertical: (spacing['md'] as num?)?.toDouble() ?? 16.0,
          ),
        ),
      ),

      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: colors['primary'],
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular((borderRadiusCfg['small'] as num?)?.toDouble() ?? 8.0),
          ),
          padding: EdgeInsets.symmetric(
            horizontal: (spacing['md'] as num?)?.toDouble() ?? 16.0,
            vertical: (spacing['sm'] as num?)?.toDouble() ?? 8.0,
          ),
        ),
      ),

      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: colors['primary'],
        foregroundColor: colors['onPrimary'],
        elevation: (elevationCfg['high'] as num?)?.toDouble() ?? 6.0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular((borderRadiusCfg['large'] as num?)?.toDouble() ?? 16.0),
        ),
      ),

      cardTheme: CardThemeData(
        color: colors['cardElevated'],
        surfaceTintColor: Colors.transparent,
        elevation: (elevationCfg['low'] as num?)?.toDouble() ?? 2.0,
        shadowColor: colors['textPrimary']!.withOpacity(0.08),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular((borderRadiusCfg['medium'] as num?)?.toDouble() ?? 12.0),
        ),
        margin: EdgeInsets.symmetric(
          horizontal: (spacing['xs'] as num?)?.toDouble() ?? 4.0,
          vertical: (spacing['xs'] as num?)?.toDouble() ?? 4.0,
        ),
      ),

      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: colors['surface'],
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular((borderRadiusCfg['medium'] as num?)?.toDouble() ?? 12.0),
          borderSide: BorderSide(color: colors['divider']!.withOpacity(0.3)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular((borderRadiusCfg['medium'] as num?)?.toDouble() ?? 12.0),
          borderSide: BorderSide(color: colors['divider']!.withOpacity(0.3)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular((borderRadiusCfg['medium'] as num?)?.toDouble() ?? 12.0),
          borderSide: BorderSide(color: colors['primary']!, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular((borderRadiusCfg['medium'] as num?)?.toDouble() ?? 12.0),
          borderSide: BorderSide(color: colors['error']!, width: 1),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular((borderRadiusCfg['medium'] as num?)?.toDouble() ?? 12.0),
          borderSide: BorderSide(color: colors['error']!, width: 2),
        ),
        contentPadding: EdgeInsets.symmetric(
          vertical: (spacing['md'] as num?)?.toDouble() ?? 16.0,
          horizontal: (spacing['md'] as num?)?.toDouble() ?? 16.0,
        ),
        hintStyle: TextStyle(color: colors['textSecondary']!.withOpacity(0.7)),
        labelStyle: TextStyle(color: colors['textSecondary']),
      ),

      drawerTheme: DrawerThemeData(
        backgroundColor: colors['surface'],
        surfaceTintColor: Colors.transparent,
        elevation: (elevationCfg['high'] as num?)?.toDouble() ?? 16.0,
        shadowColor: colors['textPrimary']!.withOpacity(0.15),
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.only(
            topRight: Radius.circular(0),
            bottomRight: Radius.circular(0),
          ),
        ),
      ),

      listTileTheme: ListTileThemeData(
        contentPadding: EdgeInsets.symmetric(
          horizontal: (spacing['md'] as num?)?.toDouble() ?? 16.0,
          vertical: (spacing['xs'] as num?)?.toDouble() ?? 4.0,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular((borderRadiusCfg['medium'] as num?)?.toDouble() ?? 12.0),
        ),
      ),

      textTheme: TextTheme(
        displayLarge: TextStyle(
          color: colors['textPrimary'], 
          fontWeight: FontWeight.w300, 
          fontSize: 57, 
          letterSpacing: -0.25,
          height: 1.12,
        ),
        displayMedium: TextStyle(
          color: colors['textPrimary'], 
          fontWeight: FontWeight.w300, 
          fontSize: 45, 
          letterSpacing: 0,
          height: 1.16,
        ),
        displaySmall: TextStyle(
          color: colors['textPrimary'], 
          fontWeight: FontWeight.w400, 
          fontSize: 36, 
          letterSpacing: 0,
          height: 1.22,
        ),
        headlineLarge: TextStyle(
          color: colors['textPrimary'], 
          fontWeight: FontWeight.w400, 
          fontSize: 32, 
          letterSpacing: 0,
          height: 1.25,
        ),
        headlineMedium: TextStyle(
          color: colors['textPrimary'], 
          fontWeight: FontWeight.w400, 
          fontSize: 28, 
          letterSpacing: 0,
          height: 1.29,
        ),
        headlineSmall: TextStyle(
          color: colors['textPrimary'], 
          fontWeight: FontWeight.w600, 
          fontSize: 24, 
          letterSpacing: 0,
          height: 1.33,
        ),
        titleLarge: TextStyle(
          color: colors['textPrimary'], 
          fontWeight: FontWeight.w600, 
          fontSize: 22, 
          letterSpacing: 0,
          height: 1.27,
        ),
        titleMedium: TextStyle(
          color: colors['textPrimary'], 
          fontWeight: FontWeight.w500, 
          fontSize: 16, 
          letterSpacing: 0.15,
          height: 1.50,
        ),
        titleSmall: TextStyle(
          color: colors['textPrimary'], 
          fontWeight: FontWeight.w500, 
          fontSize: 14, 
          letterSpacing: 0.1,
          height: 1.43,
        ),
        bodyLarge: TextStyle(
          color: colors['textPrimary'], 
          fontWeight: FontWeight.w400, 
          fontSize: 16, 
          letterSpacing: 0.5,
          height: 1.50,
        ),
        bodyMedium: TextStyle(
          color: colors['textSecondary'], 
          fontWeight: FontWeight.w400, 
          fontSize: 14, 
          letterSpacing: 0.25,
          height: 1.43,
        ),
        bodySmall: TextStyle(
          color: colors['textSecondary'], 
          fontWeight: FontWeight.w400, 
          fontSize: 12, 
          letterSpacing: 0.4,
          height: 1.33,
        ),
        labelLarge: TextStyle(
          color: colors['textPrimary'], 
          fontWeight: FontWeight.w500, 
          fontSize: 14, 
          letterSpacing: 0.1,
          height: 1.43,
        ),
        labelMedium: TextStyle(
          color: colors['textSecondary'], 
          fontWeight: FontWeight.w500, 
          fontSize: 12, 
          letterSpacing: 0.5,
          height: 1.33,
        ),
        labelSmall: TextStyle(
          color: colors['textSecondary'], 
          fontWeight: FontWeight.w500, 
          fontSize: 11, 
          letterSpacing: 0.5,
          height: 1.45,
        ),
      ),

      iconTheme: IconThemeData(
        color: colors['textPrimary'], 
        size: 24,
      ),
      
      primaryIconTheme: IconThemeData(
        color: colors['primary'], 
        size: 24,
      ),

      dividerTheme: DividerThemeData(
        color: colors['divider']!.withOpacity(0.12), 
        thickness: 1,
        space: 1,
      ),

      progressIndicatorTheme: ProgressIndicatorThemeData(
        color: colors['primary'],
        linearTrackColor: colors['primary']!.withOpacity(0.2),
        circularTrackColor: colors['primary']!.withOpacity(0.2),
      ),

      snackBarTheme: SnackBarThemeData(
        backgroundColor: colors['primaryVariant'],
        contentTextStyle: TextStyle(color: colors['onPrimary']),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular((borderRadiusCfg['medium'] as num?)?.toDouble() ?? 12.0),
        ),
        behavior: SnackBarBehavior.floating,
        elevation: (elevationCfg['medium'] as num?)?.toDouble() ?? 6.0,
      ),

      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: colors['surface'],
        selectedItemColor: colors['primary'],
        unselectedItemColor: colors['textSecondary'],
        type: BottomNavigationBarType.fixed,
        elevation: (elevationCfg['medium'] as num?)?.toDouble() ?? 8.0,
      ),

      tabBarTheme: TabBarThemeData(
        labelColor: colors['primary'],
        unselectedLabelColor: colors['textSecondary'],
        indicator: UnderlineTabIndicator(
          borderSide: BorderSide(color: colors['primary']!, width: 2),
        ),
      ),
    );
  }

  Map<String, dynamic> _getDefaultThemeConfig() {
    return {
      'colors': {
        'primary': '#E16B3A',
        'primaryVariant': '#1B3943',
        'secondary': '#FBECE6',
        'surface': '#F8F9FA',
        'background': '#FFFFFF',
        'onPrimary': '#FFFFFF',
        'onSurface': '#1F2937',
        'onBackground': '#1F2937',
        'textPrimary': '#1F2937',
        'textSecondary': '#6B7280',
        'success': '#10B981',
        'warning': '#F59E0B',
        'error': '#EF4444',
        'info': '#3B82F6',
        'cardElevated': '#FFFFFF',
        'divider': '#E5E7EB',
        'loginBgLeft': '#FBECE6',
        'loginBgRight': '#F7F7F7',
        'loginTextTitle': '#1f2937',
        'loginTextBody': '#6b7280',
        'loginTextLink': '#E16B3A',
      },
      'imageUrls': {
        'logo_image': null,
        'login_left_bg_image': null,
        'login_right_bg_image': null
      },
      'typography': {
        'fontFamily': 'Inter',
        'headlineLarge': 32.0,
        'headlineMedium': 28.0,
        'headlineSmall': 24.0,
        'titleLarge': 22.0,
        'titleMedium': 16.0,
        'titleSmall': 14.0,
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
        'xl': 24.0,
      },
      'elevation': {
        'none': 0.0,
        'low': 2.0,
        'medium': 4.0,
        'high': 8.0,
        'highest': 16.0,
      },
      'source': 'default',
      'last_updated': DateTime.now().toIso8601String(),
    };
  }
  
  Map<String, Color> _getDefaultColors() {
    final Map<String, Color> colors = {};
    (_getDefaultThemeConfig()['colors'] as Map<String, String>).forEach((key, value) {
      colors[key] = Color(int.parse('0xFF${value.substring(1)}'));
    });
    return colors;
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
        1
      );
    }
    return MaterialColor(color.value, swatch);
  }

  Color getColor(String colorKey) {
    return _themeColors?[colorKey] ?? _getDefaultColors()[colorKey] ?? _getDefaultColors()['textSecondary']!;
  }

  double getSpacing(String spacingKey) {
    final spacing = _themeConfig?['spacing'] as Map<String, dynamic>? ?? {};
    final defaultSpacing = _getDefaultThemeConfig()['spacing'] as Map<String, dynamic>;
    return (spacing[spacingKey] as num?)?.toDouble() ?? (defaultSpacing[spacingKey] as num?)?.toDouble() ?? 16.0;
  }

  double getBorderRadius(String radiusKey) {
    final borderRadius = _themeConfig?['borderRadius'] as Map<String, dynamic>? ?? {};
    final defaultRadii = _getDefaultThemeConfig()['borderRadius'] as Map<String, dynamic>;
    return (borderRadius[radiusKey] as num?)?.toDouble() ?? (defaultRadii[radiusKey] as num?)?.toDouble() ?? 12.0;
  }

  double getElevation(String elevationKey) {
    final elevation = _themeConfig?['elevation'] as Map<String, dynamic>? ?? {};
    final defaultElevation = _getDefaultThemeConfig()['elevation'] as Map<String, dynamic>;
    return (elevation[elevationKey] as num?)?.toDouble() ?? (defaultElevation[elevationKey] as num?)?.toDouble() ?? 4.0;
  }
  
  LinearGradient getDynamicButtonGradient() {
    return LinearGradient(
      colors: [
        getColor('primary'),
        getColor('primaryVariant'),
      ],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    );
  }

  LinearGradient getDynamicBackgroundGradient() {
    return LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [
        getColor('loginBgLeft'),
        getColor('loginBgRight'),
      ],
    );
  }

  LinearGradient getCardGradient() {
    return LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [
        getColor('surface'),
        getColor('cardElevated'),
      ],
    );
  }

  LinearGradient getWelcomeGradient() {
    return LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [
        getColor('primary').withOpacity(0.1),
        getColor('primaryVariant').withOpacity(0.05),
      ],
    );
  }

  BoxDecoration getDynamicCardDecoration({
    List<BoxShadow>? boxShadow,
    BorderRadius? borderRadius,
    Color? color,
  }) {
    return BoxDecoration(
      color: color ?? getColor('cardElevated'),
      borderRadius: borderRadius ?? BorderRadius.circular(getBorderRadius('medium')),
      boxShadow: boxShadow ?? [
        BoxShadow(
          color: getColor('textPrimary').withOpacity(0.05),
          spreadRadius: 0,
          blurRadius: getElevation('medium') * 2,
          offset: const Offset(0, 2),
        ),
        BoxShadow(
          color: getColor('textPrimary').withOpacity(0.03),
          spreadRadius: 0,
          blurRadius: getElevation('low'),
          offset: const Offset(0, 1),
        ),
      ],
    );
  }

  BoxDecoration getGlassmorphismDecoration({
    double opacity = 0.1,
    double blur = 10.0,
  }) {
    return BoxDecoration(
      color: getColor('cardElevated').withOpacity(opacity),
      borderRadius: BorderRadius.circular(getBorderRadius('medium')),
      border: Border.all(
        color: getColor('divider').withOpacity(0.2),
        width: 1,
      ),
      boxShadow: [
        BoxShadow(
          color: getColor('textPrimary').withOpacity(0.1),
          spreadRadius: 0,
          blurRadius: blur,
          offset: const Offset(0, 4),
        ),
      ],
    );
  }

  BoxDecoration getElevatedCardDecoration({
    double elevation = 8.0,
    Color? color,
  }) {
    return BoxDecoration(
      color: color ?? getColor('cardElevated'),
      borderRadius: BorderRadius.circular(getBorderRadius('medium')),
      boxShadow: [
        BoxShadow(
          color: getColor('primary').withOpacity(0.1),
          spreadRadius: 0,
          blurRadius: elevation,
          offset: Offset(0, elevation / 2),
        ),
        BoxShadow(
          color: getColor('textPrimary').withOpacity(0.05),
          spreadRadius: 0,
          blurRadius: elevation / 2,
          offset: const Offset(0, 1),
        ),
      ],
    );
  }

  ButtonStyle getPrimaryButtonStyle() {
    return ElevatedButton.styleFrom(
      backgroundColor: getColor('primary'),
      foregroundColor: getColor('onPrimary'),
      elevation: getElevation('medium'),
      shadowColor: getColor('primary').withOpacity(0.4),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(getBorderRadius('medium')),
      ),
      padding: EdgeInsets.symmetric(
        horizontal: getSpacing('lg'),
        vertical: getSpacing('md'),
      ),
    );
  }

  ButtonStyle getSecondaryButtonStyle() {
    return OutlinedButton.styleFrom(
      foregroundColor: getColor('primary'),
      side: BorderSide(color: getColor('primary'), width: 1.5),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(getBorderRadius('medium')),
      ),
      padding: EdgeInsets.symmetric(
        horizontal: getSpacing('lg'),
        vertical: getSpacing('md'),
      ),
    );
  }

  Color getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'success':
      case 'completed':
      case 'active':
        return getColor('success');
      case 'warning':
      case 'pending':
      case 'in_progress':
        return getColor('warning');
      case 'error':
      case 'failed':
      case 'cancelled':
        return getColor('error');
      case 'info':
      case 'draft':
      case 'not_started':
        return getColor('info');
      default:
        return getColor('textSecondary');
    }
  }

  Widget buildGradientContainer({
    required Widget child,
    LinearGradient? gradient,
    EdgeInsets? padding,
    EdgeInsets? margin,
    BorderRadius? borderRadius,
    List<BoxShadow>? boxShadow,
  }) {
    return Container(
      margin: margin,
      padding: padding ?? EdgeInsets.all(getSpacing('md')),
      decoration: BoxDecoration(
        gradient: gradient ?? getDynamicButtonGradient(),
        borderRadius: borderRadius ?? BorderRadius.circular(getBorderRadius('medium')),
        boxShadow: boxShadow ?? [
          BoxShadow(
            color: getColor('primary').withOpacity(0.3),
            blurRadius: getElevation('medium') * 2,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: child,
    );
  }

  Widget buildFloatingCard({
    required Widget child,
    EdgeInsets? padding,
    EdgeInsets? margin,
    Color? color,
    double? elevation,
  }) {
    return Container(
      margin: margin ?? EdgeInsets.all(getSpacing('sm')),
      decoration: getDynamicCardDecoration(
        color: color,
        boxShadow: [
          BoxShadow(
            color: getColor('textPrimary').withOpacity(0.08),
            spreadRadius: 0,
            blurRadius: elevation ?? getElevation('medium'),
            offset: Offset(0, (elevation ?? getElevation('medium')) / 2),
          ),
        ],
      ),
      child: Padding(
        padding: padding ?? EdgeInsets.all(getSpacing('md')),
        child: child,
      ),
    );
  }

  InputDecoration getInputDecoration({
    String? labelText,
    String? hintText,
    Widget? prefixIcon,
    Widget? suffixIcon,
    String? errorText,
  }) {
    return InputDecoration(
      labelText: labelText,
      hintText: hintText,
      prefixIcon: prefixIcon,
      suffixIcon: suffixIcon,
      errorText: errorText,
      filled: true,
      fillColor: getColor('surface'),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(getBorderRadius('medium')),
        borderSide: BorderSide(color: getColor('divider').withOpacity(0.3)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(getBorderRadius('medium')),
        borderSide: BorderSide(color: getColor('divider').withOpacity(0.3)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(getBorderRadius('medium')),
        borderSide: BorderSide(color: getColor('primary'), width: 2),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(getBorderRadius('medium')),
        borderSide: BorderSide(color: getColor('error'), width: 1),
      ),
      contentPadding: EdgeInsets.symmetric(
        vertical: getSpacing('md'),
        horizontal: getSpacing('md'),
      ),
    );
  }
}