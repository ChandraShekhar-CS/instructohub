import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'api_service.dart';

class IconService {
  static IconService? _instance;
  Map<String, IconData>? _iconMappings;
  bool _isLoaded = false;

  IconService._internal();

  static IconService get instance {
    _instance ??= IconService._internal();
    return _instance!;
  }

  // Default fallback icons
  static const Map<String, IconData> _defaultIcons = {
    'settings': Icons.settings,
    'person': Icons.person_outline,
    'lock': Icons.lock_outline,
    'visibility_on': Icons.visibility_outlined,
    'visibility_off': Icons.visibility_off_outlined,
    'check': Icons.check,
    'school': Icons.school,
    'domain': Icons.domain,
    'info': Icons.info_outline,
    'swap': Icons.swap_horiz,
    'logout': Icons.logout,
    'menu': Icons.menu,
    'home': Icons.home_outlined,
    'courses': Icons.book_outlined,
    'dashboard': Icons.dashboard_outlined,
    'calendar': Icons.calendar_today_outlined,
    'notifications': Icons.notifications_outlined,
    'profile': Icons.account_circle_outlined,
    'search': Icons.search,
    'arrow_forward': Icons.arrow_forward_ios,
    'play': Icons.play_circle_outline,
    'star': Icons.star_border_outlined,
    'chart': Icons.show_chart_outlined,
    'event': Icons.event_outlined,
    'history': Icons.history_outlined,
    'bolt': Icons.bolt_outlined,
    'cloud': Icons.cloud_outlined,
    'wifi': Icons.wifi_find,
    'error': Icons.error_outline,
    'success': Icons.check_circle,
    'warning': Icons.warning_outlined,
    'edit': Icons.edit_outlined,
    'delete': Icons.delete_outline,
    'add': Icons.add,
    'close': Icons.close,
    'arrow_back': Icons.arrow_back_ios,
    'refresh': Icons.refresh,
    'download': Icons.download_outlined,
    'upload': Icons.upload_outlined,
    'share': Icons.share_outlined,
    'favorite': Icons.favorite_outline,
    'more': Icons.more_vert,
  };

  // API icon name to Flutter icon mapping
  static const Map<String, IconData> _apiToFlutterMapping = {
    // Material Design icon names that might come from API
    'settings': Icons.settings,
    'cog': Icons.settings,
    'gear': Icons.settings,
    'user': Icons.person_outline,
    'person': Icons.person_outline,
    'account': Icons.account_circle_outlined,
    'password': Icons.lock_outline,
    'lock': Icons.lock_outline,
    'security': Icons.security,
    'eye': Icons.visibility_outlined,
    'eye-off': Icons.visibility_off_outlined,
    'hide': Icons.visibility_off_outlined,
    'show': Icons.visibility_outlined,
    'check': Icons.check,
    'checkmark': Icons.check,
    'tick': Icons.check,
    'school': Icons.school,
    'education': Icons.school,
    'domain': Icons.domain,
    'globe': Icons.public,
    'world': Icons.language,
    'info': Icons.info_outline,
    'information': Icons.info_outline,
    'swap': Icons.swap_horiz,
    'switch': Icons.swap_horiz,
    'exchange': Icons.swap_horiz,
    'logout': Icons.logout,
    'sign-out': Icons.logout,
    'exit': Icons.exit_to_app,
    'menu': Icons.menu,
    'hamburger': Icons.menu,
    'bars': Icons.menu,
    'home': Icons.home_outlined,
    'house': Icons.home_outlined,
    'dashboard': Icons.dashboard_outlined,
    'grid': Icons.grid_view,
    'book': Icons.book_outlined,
    'course': Icons.book_outlined,
    'study': Icons.book_outlined,
    'calendar': Icons.calendar_today_outlined,
    'date': Icons.calendar_today_outlined,
    'schedule': Icons.schedule,
    'bell': Icons.notifications_outlined,
    'notification': Icons.notifications_outlined,
    'alert': Icons.notifications_outlined,
    'search': Icons.search,
    'find': Icons.search,
    'magnify': Icons.search,
    'arrow-right': Icons.arrow_forward_ios,
    'arrow-left': Icons.arrow_back_ios,
    'arrow-forward': Icons.arrow_forward,
    'arrow-back': Icons.arrow_back,
    'play': Icons.play_circle_outline,
    'start': Icons.play_circle_outline,
    'star': Icons.star_border_outlined,
    'favorite': Icons.favorite_outline,
    'heart': Icons.favorite_outline,
    'chart': Icons.show_chart_outlined,
    'graph': Icons.bar_chart,
    'analytics': Icons.analytics_outlined,
    'event': Icons.event_outlined,
    'calendar-event': Icons.event,
    'history': Icons.history_outlined,
    'time': Icons.access_time,
    'clock': Icons.schedule,
    'lightning': Icons.bolt_outlined,
    'flash': Icons.flash_on,
    'thunder': Icons.bolt_outlined,
    'cloud': Icons.cloud_outlined,
    'server': Icons.dns,
    'database': Icons.storage,
    'wifi': Icons.wifi,
    'signal': Icons.signal_wifi_4_bar,
    'network': Icons.network_check,
    'error': Icons.error_outline,
    'warning': Icons.warning_outlined,
    'success': Icons.check_circle,
    'complete': Icons.check_circle,
    'done': Icons.done,
    'edit': Icons.edit_outlined,
    'pencil': Icons.edit,
    'modify': Icons.edit_outlined,
    'delete': Icons.delete_outline,
    'trash': Icons.delete,
    'remove': Icons.remove,
    'add': Icons.add,
    'plus': Icons.add,
    'create': Icons.add_circle_outline,
    'close': Icons.close,
    'cancel': Icons.cancel_outlined,
    'refresh': Icons.refresh,
    'reload': Icons.refresh,
    'sync': Icons.sync,
    'download': Icons.download_outlined,
    'upload': Icons.upload_outlined,
    'share': Icons.share_outlined,
    'send': Icons.send,
    'more': Icons.more_vert,
    'dots': Icons.more_horiz,
    'options': Icons.more_vert,
  };

  Future<void> loadIcons({String? token}) async {
    if (_isLoaded) return;

    try {
      // Try to load from cache first
      final cachedIcons = await _loadFromCache();
      if (cachedIcons != null) {
        _iconMappings = cachedIcons;
        _isLoaded = true;
        return;
      }

      // Fetch from API if available
      if (token != null && ApiService.instance.isConfigured) {
        final apiIcons = await _fetchFromAPI(token);
        if (apiIcons != null) {
          _iconMappings = apiIcons;
          await _saveToCache(apiIcons);
          _isLoaded = true;
          return;
        }
      }

      // Fallback to default icons
      _iconMappings = Map.from(_defaultIcons);
      _isLoaded = true;
    } catch (e) {
      print('Error loading icons: $e');
      _iconMappings = Map.from(_defaultIcons);
      _isLoaded = true;
    }
  }

  Future<Map<String, IconData>?> _fetchFromAPI(String token) async {
    try {
      // Fetch icon configuration from your API
      final response = await ApiService.instance.callCustomAPI(
        'local_instructohub_get_icon_config', // Your API function
        token,
        {},
        method: 'GET',
      );

      if (response != null && response['icons'] != null) {
        return _parseAPIIcons(response['icons']);
      }
    } catch (e) {
      print('Failed to fetch icons from API: $e');
    }
    return null;
  }

  Map<String, IconData> _parseAPIIcons(Map<String, dynamic> apiIcons) {
    final Map<String, IconData> iconMap = {};
    
    apiIcons.forEach((key, value) {
      if (value is String) {
        // Map API icon name to Flutter icon
        final flutterIcon = _apiToFlutterMapping[value.toLowerCase()] ?? 
                           _defaultIcons[key] ?? 
                           Icons.help_outline;
        iconMap[key] = flutterIcon;
      }
    });

    // Ensure all default icons are present
    _defaultIcons.forEach((key, value) {
      iconMap.putIfAbsent(key, () => value);
    });

    return iconMap;
  }

  Future<Map<String, IconData>?> _loadFromCache() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final cachedData = prefs.getString('cached_icons');
      if (cachedData != null) {
        final Map<String, dynamic> data = json.decode(cachedData);
        final Map<String, IconData> iconMap = {};
        
        data.forEach((key, value) {
          if (value is String) {
            final icon = _apiToFlutterMapping[value] ?? _defaultIcons[key] ?? Icons.help_outline;
            iconMap[key] = icon;
          }
        });
        
        return iconMap;
      }
    } catch (e) {
      print('Error loading cached icons: $e');
    }
    return null;
  }

  Future<void> _saveToCache(Map<String, IconData> icons) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final Map<String, String> cacheData = {};
      
      icons.forEach((key, value) {
        // Find the API name for this icon
        final apiName = _apiToFlutterMapping.entries
            .firstWhere((entry) => entry.value == value, orElse: () => MapEntry(key, value))
            .key;
        cacheData[key] = apiName;
      });
      
      await prefs.setString('cached_icons', json.encode(cacheData));
    } catch (e) {
      print('Error caching icons: $e');
    }
  }

  IconData getIcon(String iconKey) {
    if (!_isLoaded) {
      return _defaultIcons[iconKey] ?? Icons.help_outline;
    }
    return _iconMappings?[iconKey] ?? _defaultIcons[iconKey] ?? Icons.help_outline;
  }

  Future<void> clearCache() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('cached_icons');
      _iconMappings = null;
      _isLoaded = false;
    } catch (e) {
      print('Error clearing icon cache: $e');
    }
  }

  // Convenience methods for commonly used icons
  IconData get settingsIcon => getIcon('settings');
  IconData get personIcon => getIcon('person');
  IconData get lockIcon => getIcon('lock');
  IconData get visibilityOnIcon => getIcon('visibility_on');
  IconData get visibilityOffIcon => getIcon('visibility_off');
  IconData get checkIcon => getIcon('check');
  IconData get schoolIcon => getIcon('school');
  IconData get domainIcon => getIcon('domain');
  IconData get infoIcon => getIcon('info');
  IconData get swapIcon => getIcon('swap');
  IconData get logoutIcon => getIcon('logout');
  IconData get homeIcon => getIcon('home');
  IconData get dashboardIcon => getIcon('dashboard');
  IconData get coursesIcon => getIcon('courses');
  IconData get searchIcon => getIcon('search');
  IconData get playIcon => getIcon('play');
  IconData get starIcon => getIcon('star');
  IconData get chartIcon => getIcon('chart');
  IconData get eventIcon => getIcon('event');
  IconData get historyIcon => getIcon('history');
  IconData get boltIcon => getIcon('bolt');
  IconData get cloudIcon => getIcon('cloud');
  IconData get arrowForwardIcon => getIcon('arrow_forward');
}