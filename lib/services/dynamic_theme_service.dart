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

  final List<VoidCallback> _listeners = [];

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

  void addListener(VoidCallback listener) {
    _listeners.add(listener);
  }

  void removeListener(VoidCallback listener) {
    _listeners.remove(listener);
  }

  void _notifyListeners() {
    for (var listener in _listeners) {
      try {
        listener();
      } catch (e) {
        // Error in theme listener
      }
    }
  }

  // MODIFICATION: The loadTheme method now accepts an optional tenantName.
  Future<void> loadTheme({String? tenantName, String? token}) async {
    try {
      Map<String, dynamic>? remoteTheme;
      String? fetchedSiteName;
      String? fetchedLogoUrl;

      // Prioritize the tenantName passed as a parameter. Fallback to the one from ApiService.
      final effectiveTenantName = tenantName ?? ApiService.instance.tenantName;

      if (effectiveTenantName.isNotEmpty) {
        // Pass the tenant name to the fetch method.
        remoteTheme = await _fetchAndProcessRemoteTheme(tenantName: effectiveTenantName);

        try {
          final siteInfo = await ApiService.instance.callCustomAPI('core_webservice_get_site_info', token ?? '', {});
          if (siteInfo != null && siteInfo['sitename'] != null) {
            fetchedSiteName = siteInfo['sitename'];
            fetchedLogoUrl = remoteTheme?['imageUrls']?['logo_image'] ?? siteInfo['userpictureurl'];
          }
        } catch (e) {
          // Could not fetch site name, will use fallback.
        }
      }
      
      final cachedTheme = await _loadCachedTheme();
      Map<String, dynamic> finalThemeConfig;

      if (remoteTheme != null && _isValidThemeConfig(remoteTheme)) {
        finalThemeConfig = remoteTheme;
        finalThemeConfig['siteName'] = fetchedSiteName ?? effectiveTenantName.toUpperCase();
        finalThemeConfig['logoUrl'] = fetchedLogoUrl ?? finalThemeConfig['imageUrls']?['logo_image'];
        await _saveCachedTheme(finalThemeConfig);
      } else if (cachedTheme != null && _isValidThemeConfig(cachedTheme)) {
        finalThemeConfig = cachedTheme;
      } else {
        finalThemeConfig = _getDefaultThemeConfig();
        finalThemeConfig['siteName'] = fetchedSiteName ?? 'InstructoHub';
      }
      
      _applyThemeConfig(finalThemeConfig);
      _isLoaded = true;
    } catch (e) {
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
    
    _notifyListeners();
  }

  void _loadDefaultTheme() {
    final defaultConfig = _getDefaultThemeConfig();
    defaultConfig['siteName'] = 'InstructoHub';
    _applyThemeConfig(defaultConfig);
    _isLoaded = true;
  }
  
  // MODIFICATION: This method now requires a tenantName to build the URL.
  Future<Map<String, dynamic>?> _fetchAndProcessRemoteTheme({required String tenantName}) async {
    // MODIFICATION: Construct the API URL dynamically.
    final String apiUrl = 'https://$tenantName.mdl.instructohub.com/local/instructohub/theme.php';
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
      }
    } catch (e) {
      // Exception during theme fetch or processing
    }
    return null;
  }
  
  Map<String, String> _remapApiColors(Map<String, dynamic> apiColors) {
    String? getApiColor(String key) => apiColors[key] is String ? apiColors[key] : null;

    final defaultColors = _getDefaultThemeConfig()['colors'] as Map<String, String>;
    
    return {
      'primary': getApiColor('secondary1') ?? defaultColors['primary']!,
      'primaryLight': getApiColor('secondary3') ?? defaultColors['primaryLight']!,
      'primaryDark': getApiColor('secondary2') ?? defaultColors['primaryDark']!,
      'surface': '#FFFFFF',
      'background': '#F8FAFC',
      'backgroundLight': '#FFFFFF',
      'cardBackground': '#FFFFFF',
      'onPrimary': '#FFFFFF',
      'onSurface': getApiColor('primary1') ?? defaultColors['onSurface']!,
      'onBackground': getApiColor('primary1') ?? defaultColors['onBackground']!,
      'textPrimary': getApiColor('primary1') ?? defaultColors['textPrimary']!,
      'textSecondary': getApiColor('primary2') ?? defaultColors['textSecondary']!,
      'textMuted': '#94A3B8',
      'border': '#E2E8F0',
      'borderLight': '#F1F5F9',
      'success': '#10B981',
      'warning': '#F59E0B',
      'error': '#EF4444',
      'info': '#3B82F6',
      'shadow': '#64748B',
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
      await prefs.setString('dynamic_theme_v7', json.encode(themeConfig));
    } catch (e) {
      // Error saving cached theme
    }
  }

  Future<Map<String, dynamic>?> _loadCachedTheme() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final cachedData = prefs.getString('dynamic_theme_v7');
      if (cachedData != null) {
        return Map<String, dynamic>.from(json.decode(cachedData));
      }
    } catch (e) {
      // Error loading cached theme
    }
    return null;
  }
  
  Future<void> clearThemeCache() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('dynamic_theme_v7');
      forceReload();
      _notifyListeners();
    } catch (e) {
      // Error clearing theme cache
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
    return ThemeData(
      useMaterial3: true,
      primarySwatch: _createMaterialColor(colors['primary']!),
      fontFamily: 'Inter',
      
      colorScheme: ColorScheme.light(
        brightness: Brightness.light,
        primary: colors['primary']!,
        onPrimary: colors['onPrimary']!,
        secondary: colors['primaryLight']!,
        onSecondary: colors['onPrimary']!,
        error: colors['error']!,
        onError: colors['onPrimary']!,
        background: colors['background']!,
        onBackground: colors['onBackground']!,
        surface: colors['surface']!,
        onSurface: colors['onSurface']!,
        outline: colors['border']!,
        shadow: colors['shadow']!.withOpacity(0.15),
      ),

      scaffoldBackgroundColor: colors['background'],

      appBarTheme: AppBarTheme(
        backgroundColor: colors['backgroundLight'],
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 1,
        shadowColor: colors['shadow']!.withOpacity(0.1),
        iconTheme: IconThemeData(color: colors['textPrimary'], size: 24),
        titleTextStyle: TextStyle(
          color: colors['textPrimary'],
          fontSize: 20,
          fontWeight: FontWeight.w600,
          fontFamily: 'Inter',
        ),
        centerTitle: false,
      ),

      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: colors['primary'],
          foregroundColor: colors['onPrimary'],
          elevation: 0,
          shadowColor: Colors.transparent,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          textStyle: const TextStyle(
            fontWeight: FontWeight.w500,
            fontSize: 14,
            fontFamily: 'Inter',
          ),
        ),
      ),

      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: colors['primary'],
          side: BorderSide(color: colors['border']!, width: 1),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        ),
      ),

      cardTheme: CardThemeData(
        color: colors['cardBackground'],
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        shadowColor: colors['shadow']!.withOpacity(0.1),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(0),
      ),

      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: colors['surface'],
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: colors['border']!),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: colors['border']!),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: colors['primary']!, width: 2),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        hintStyle: TextStyle(color: colors['textMuted']),
      ),

      textTheme: TextTheme(
        displayLarge: TextStyle(color: colors['textPrimary'], fontWeight: FontWeight.w700, fontSize: 32),
        displayMedium: TextStyle(color: colors['textPrimary'], fontWeight: FontWeight.w700, fontSize: 28),
        displaySmall: TextStyle(color: colors['textPrimary'], fontWeight: FontWeight.w600, fontSize: 24),
        headlineLarge: TextStyle(color: colors['textPrimary'], fontWeight: FontWeight.w600, fontSize: 22),
        headlineMedium: TextStyle(color: colors['textPrimary'], fontWeight: FontWeight.w600, fontSize: 20),
        headlineSmall: TextStyle(color: colors['textPrimary'], fontWeight: FontWeight.w600, fontSize: 18),
        titleLarge: TextStyle(color: colors['textPrimary'], fontWeight: FontWeight.w600, fontSize: 16),
        titleMedium: TextStyle(color: colors['textPrimary'], fontWeight: FontWeight.w500, fontSize: 14),
        titleSmall: TextStyle(color: colors['textPrimary'], fontWeight: FontWeight.w500, fontSize: 12),
        bodyLarge: TextStyle(color: colors['textPrimary'], fontWeight: FontWeight.w400, fontSize: 16),
        bodyMedium: TextStyle(color: colors['textSecondary'], fontWeight: FontWeight.w400, fontSize: 14),
        bodySmall: TextStyle(color: colors['textMuted'], fontWeight: FontWeight.w400, fontSize: 12),
        labelLarge: TextStyle(color: colors['textPrimary'], fontWeight: FontWeight.w500, fontSize: 14),
        labelMedium: TextStyle(color: colors['textSecondary'], fontWeight: FontWeight.w500, fontSize: 12),
        labelSmall: TextStyle(color: colors['textMuted'], fontWeight: FontWeight.w500, fontSize: 11),
      ),

      iconTheme: IconThemeData(color: colors['textPrimary'], size: 24),
      dividerTheme: DividerThemeData(color: colors['border'], thickness: 1),
      progressIndicatorTheme: ProgressIndicatorThemeData(color: colors['primary']),
    );
  }

  Map<String, dynamic> _getDefaultThemeConfig() {
    return {
      'colors': {
        'primary': '#8B5CF6',
        'primaryLight': '#A78BFA',
        'primaryDark': '#7C3AED',
        'surface': '#FFFFFF',
        'background': '#F8FAFC',
        'backgroundLight': '#FFFFFF',
        'cardBackground': '#FFFFFF',
        'onPrimary': '#FFFFFF',
        'onSurface': '#1E293B',
        'onBackground': '#1E293B',
        'textPrimary': '#1E293B',
        'textSecondary': '#64748B',
        'textMuted': '#94A3B8',
        'border': '#E2E8F0',
        'borderLight': '#F1F5F9',
        'success': '#10B981',
        'warning': '#F59E0B',
        'error': '#EF4444',
        'info': '#3B82F6',
        'shadow': '#64748B',
        'loginBgLeft': '#FBECE6',
        'loginBgRight': '#F7F7F7',
        'loginTextTitle': '#1f2937',
        'loginTextBody': '#6b7280',
        'loginTextLink': '#8B5CF6',
      },
      'imageUrls': {
        'logo_image': null,
        'login_left_bg_image': null,
        'login_right_bg_image': null
      },
      'spacing': {
        'xs': 4.0,
        'sm': 8.0,
        'md': 16.0,
        'lg': 24.0,
        'xl': 32.0,
      },
      'borderRadius': {
        'small': 6.0,
        'medium': 8.0,
        'large': 12.0,
        'xl': 16.0,
      },
      'elevation': {
        'none': 0.0,
        'low': 1.0,
        'medium': 2.0,
        'high': 4.0,
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
    return (borderRadius[radiusKey] as num?)?.toDouble() ?? (defaultRadii[radiusKey] as num?)?.toDouble() ?? 8.0;
  }

  BoxShadow getCardShadow({double opacity = 0.05}) {
    return BoxShadow(
      color: getColor('shadow').withOpacity(opacity),
      spreadRadius: 0,
      blurRadius: 10,
      offset: const Offset(0, 4),
    );
  }

  BoxDecoration getCleanCardDecoration({
    Color? backgroundColor,
    double? borderRadius,
    Color? borderColor,
    List<BoxShadow>? customShadow,
  }) {
    return BoxDecoration(
      color: backgroundColor ?? getColor('cardBackground'),
      borderRadius: BorderRadius.circular(borderRadius ?? getBorderRadius('large')),
      border: borderColor != null ? Border.all(color: borderColor, width: 1) : null,
      boxShadow: customShadow ?? [getCardShadow()],
    );
  }

  Widget buildCleanCard({
    required Widget child,
    EdgeInsets? padding,
    EdgeInsets? margin,
    Color? backgroundColor,
    VoidCallback? onTap,
  }) {
    Widget cardContent = Container(
      margin: margin,
      decoration: getCleanCardDecoration(backgroundColor: backgroundColor),
      child: Padding(
        padding: padding ?? EdgeInsets.all(getSpacing('md')),
        child: child,
      ),
    );

    if (onTap != null) {
      return Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(getBorderRadius('large')),
          child: cardContent,
        ),
      );
    }

    return cardContent;
  }

  Widget buildMetricCard({
    required String title,
    required String value,
    required IconData icon,
    required Color iconColor,
  }) {
    return buildCleanCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: EdgeInsets.all(getSpacing('xs')),
                decoration: BoxDecoration(
                  color: iconColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(getBorderRadius('small')),
                ),
                child: Icon(icon, color: iconColor, size: 20),
              ),
              const Spacer(),
              Text(
                value,
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w700,
                  color: getColor('textPrimary'),
                ),
              ),
            ],
          ),
          SizedBox(height: getSpacing('sm')),
          Text(
            title,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: getColor('textSecondary'),
            ),
          ),
        ],
      ),
    );
  }

  Widget buildSectionHeader({
    required String title,
    String? actionText,
    VoidCallback? onActionTap,
  }) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: getSpacing('md')),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            title,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: getColor('textPrimary'),
            ),
          ),
          if (actionText != null && onActionTap != null)
            TextButton(
              onPressed: onActionTap,
              child: Text(
                actionText,
                style: TextStyle(
                  color: getColor('primary'),
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
        ],
      ),
    );
  }
}
