

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'api_service.dart';
import 'configuration_service.dart';

class DynamicIconService {
  static DynamicIconService? _instance;
  Map<String, IconData>? _iconMappings;
  Map<String, String>? _iconStyles;
  Map<String, dynamic>? _iconConfig;
  bool _isLoaded = false;

  DynamicIconService._internal();

  static DynamicIconService get instance {
    _instance ??= DynamicIconService._internal();
    return _instance!;
  }

  bool get isLoaded => _isLoaded;

  static const Map<String, IconData> _materialIcons = {
    // Basic UI Icons
    'home': Icons.home,
    'home_outlined': Icons.home_outlined,
    'home_filled': Icons.home,
    'dashboard': Icons.dashboard,
    'dashboard_outlined': Icons.dashboard_outlined,
    'menu': Icons.menu,
    'more_vert': Icons.more_vert,
    'more_horiz': Icons.more_horiz,
    'close': Icons.close,
    'check': Icons.check,
    'add': Icons.add,
    'remove': Icons.remove,
    'edit': Icons.edit,
    'delete': Icons.delete,
    'save': Icons.save,
    'cancel': Icons.cancel,
    'quick_actions': Icons.arrow_forward_ios,

    // Navigation Icons
    'arrow_back': Icons.arrow_back,
    'arrow_forward': Icons.arrow_forward,
    'arrow_back_ios': Icons.arrow_back_ios,
    'arrow_forward_ios': Icons.arrow_forward_ios,
    'expand_more': Icons.expand_more,
    'expand_less': Icons.expand_less,
    'chevron_left': Icons.chevron_left,
    'chevron_right': Icons.chevron_right,

    // User & Auth Icons
    'person': Icons.person,
    'person_outline': Icons.person_outline,
    'account_circle': Icons.account_circle,
    'account_circle_outlined': Icons.account_circle_outlined,
    'login': Icons.login,
    'logout': Icons.logout,
    'lock': Icons.lock,
    'lock_outline': Icons.lock_outline,
    'security': Icons.security,
    'key': Icons.key,

    // Visibility Icons
    'visibility': Icons.visibility,
    'visibility_outlined': Icons.visibility_outlined,
    'visibility_off': Icons.visibility_off,
    'visibility_off_outlined': Icons.visibility_off_outlined,

    // Education Icons
    'school': Icons.school,
    'book': Icons.book,
    'book_outlined': Icons.book_outlined,
    'library_books': Icons.library_books,
    'menu_book': Icons.menu_book,
    'auto_stories': Icons.auto_stories,
    'assignment': Icons.assignment,
    'assignment_outlined': Icons.assignment_outlined,
    'quiz': Icons.quiz,
    'grade': Icons.grade,
    'psychology': Icons.psychology,

    // Communication Icons
    'chat': Icons.chat,
    'chat_outlined': Icons.chat_outlined,
    'forum': Icons.forum,
    'comment': Icons.comment,
    'message': Icons.message,
    'email': Icons.email,
    'mail_outline': Icons.mail_outline,
    'send': Icons.send,
    'reply': Icons.reply,

    // Media & Content Icons
    'play_arrow': Icons.play_arrow,
    'play_circle': Icons.play_circle,
    'play_circle_outline': Icons.play_circle_outline,
    'pause': Icons.pause,
    'stop': Icons.stop,
    'video_library': Icons.video_library,
    'videocam': Icons.videocam,
    'image': Icons.image,
    'photo_library': Icons.photo_library,
    'attach_file': Icons.attach_file,
    'cloud_upload': Icons.cloud_upload,
    'cloud_download': Icons.cloud_download,
    'download': Icons.download,
    'upload': Icons.upload,

    // Status & Feedback Icons
    'notifications': Icons.notifications,
    'notifications_outlined': Icons.notifications_outlined,
    'notification_important': Icons.notification_important,
    'star': Icons.star,
    'star_border': Icons.star_border,
    'star_outlined': Icons.star_border_outlined,
    'favorite': Icons.favorite,
    'favorite_outline': Icons.favorite_outline,
    'thumb_up': Icons.thumb_up,
    'thumb_down': Icons.thumb_down,

    // System & Settings Icons
    'settings': Icons.settings,
    'settings_outlined': Icons.settings_outlined,
    'tune': Icons.tune,
    'palette': Icons.palette,
    'brightness_6': Icons.brightness_6,
    'dark_mode': Icons.dark_mode,
    'light_mode': Icons.light_mode,
    'language': Icons.language,
    'translate': Icons.translate,

    // Data & Analytics Icons
    'analytics': Icons.analytics,
    'analytics_outlined': Icons.analytics_outlined,
    'bar_chart': Icons.bar_chart,
    'show_chart': Icons.show_chart,
    'pie_chart': Icons.pie_chart,
    'timeline': Icons.timeline,
    'trending_up': Icons.trending_up,
    'trending_down': Icons.trending_down,

    // Time & Calendar Icons
    'schedule': Icons.schedule,
    'access_time': Icons.access_time,
    'timer': Icons.timer,
    'today': Icons.today,
    'event': Icons.event,
    'event_outlined': Icons.event_outlined,
    'calendar_today': Icons.calendar_today,
    'calendar_month': Icons.calendar_month,
    'date_range': Icons.date_range,
    'history': Icons.history,
    'history_outlined': Icons.history_outlined,

    // Technology Icons
    'computer': Icons.computer,
    'laptop': Icons.laptop,
    'phone_android': Icons.phone_android,
    'tablet': Icons.tablet,
    'desktop_windows': Icons.desktop_windows,
    'wifi': Icons.wifi,
    'bluetooth': Icons.bluetooth,
    'cloud': Icons.cloud,
    'cloud_outlined': Icons.cloud_outlined,
    'storage': Icons.storage,
    'memory': Icons.memory,

    // Action Icons
    'search': Icons.search,
    'filter_list': Icons.filter_list,
    'sort': Icons.sort,
    'refresh': Icons.refresh,
    'sync': Icons.sync,
    'share': Icons.share,
    'share_outlined': Icons.share_outlined,
    'copy': Icons.copy,
    'content_copy': Icons.content_copy,
    'link': Icons.link,
    'open_in_new': Icons.open_in_new,

    // Status Icons
    'check_circle': Icons.check_circle,
    'check_circle_outline': Icons.check_circle_outline,
    'error': Icons.error,
    'error_outline': Icons.error_outline,
    'warning': Icons.warning,
    'warning_outlined': Icons.warning_outlined,
    'info': Icons.info,
    'info_outline': Icons.info_outline,
    'help': Icons.help,
    'help_outline': Icons.help_outline,

    // Progress & Loading Icons
    'hourglass_empty': Icons.hourglass_empty,
    'hourglass_full': Icons.hourglass_full,
    'pending': Icons.pending,
    'update': Icons.update,
    'autorenew': Icons.autorenew,

    // Misc Icons
    'flag': Icons.flag,
    'bookmark': Icons.bookmark,
    'bookmark_outline': Icons.bookmark_outline,
    'label': Icons.label,
    'tag': Icons.tag,
    'category': Icons.category,
    'folder': Icons.folder,
    'folder_open': Icons.folder_open,
    'description': Icons.description,
    'article': Icons.article,
    'note': Icons.note,
    'sticky_note_2': Icons.sticky_note_2,

    // Special LMS Icons
    'groups': Icons.groups,
    'people': Icons.people,
    'people_outline': Icons.people_outline,
    'supervisor_account': Icons.supervisor_account,
    'admin_panel_settings': Icons.admin_panel_settings,
    'badge': Icons.badge,
    'workspace_premium': Icons.workspace_premium,
    'military_tech': Icons.military_tech,
    'emoji_events': Icons.emoji_events,
    'celebration': Icons.celebration,
    'psychology_alt': Icons.psychology_alt,
    'science': Icons.science,
    'biotech': Icons.biotech,
    'engineering': Icons.engineering,
    'architecture': Icons.architecture,

    // Additional missing icons
    'location_on': Icons.location_on,
    'phone': Icons.phone,
    'library_music': Icons.library_music,
  };

  // Legacy icon names mapping
  static const Map<String, String> _legacyMapping = {
    'cog': 'settings',
    'gear': 'settings',
    'user': 'person',
    'account': 'account_circle',
    'password': 'lock',
    'eye': 'visibility',
    'eye-off': 'visibility_off',
    'hide': 'visibility_off',
    'show': 'visibility',
    'checkmark': 'check',
    'tick': 'check',
    'education': 'school',
    'globe': 'language',
    'world': 'language',
    'information': 'info',
    'swap': 'sync',
    'switch': 'sync',
    'exchange': 'sync',
    'sign-out': 'logout',
    'exit': 'logout',
    'hamburger': 'menu',
    'bars': 'menu',
    'house': 'home',
    'grid': 'dashboard',
    'course': 'book',
    'study': 'book',
    'date': 'calendar_today',
    'bell': 'notifications',
    'notification': 'notifications',
    'alert': 'notifications',
    'find': 'search',
    'magnify': 'search',
    'arrow-right': 'arrow_forward',
    'arrow-left': 'arrow_back',
    'start': 'play_arrow',
    'heart': 'favorite',
    'graph': 'bar_chart',
    'time': 'schedule',
    'clock': 'schedule',
    'lightning': 'flash_on',
    'flash': 'flash_on',
    'thunder': 'flash_on',
    'server': 'storage',
    'database': 'storage',
    'signal': 'wifi',
    'network': 'wifi',
    'complete': 'check_circle',
    'done': 'check',
    'pencil': 'edit',
    'modify': 'edit',
    'trash': 'delete',
    'plus': 'add',
    'create': 'add',
    'reload': 'refresh',
    'dots': 'more_horiz',
    'options': 'more_vert',
  };

  Future<void> loadIcons({String? token}) async {
    if (_isLoaded) return;

    try {
      await ConfigurationService.instance.initialize();

      Map<String, dynamic>? remoteConfig;
      if (token != null && ApiService.instance.isConfigured) {
        remoteConfig = await _fetchRemoteIconConfig(token);
      }

      final cachedConfig = await _loadCachedIconConfig();

      Map<String, dynamic> finalIconConfig;
      if (remoteConfig != null) {
        finalIconConfig = remoteConfig;
        await _saveCachedIconConfig(remoteConfig);
        print('✅ Using remote icon configuration');
      } else if (cachedConfig != null) {
        finalIconConfig = cachedConfig;
        print('✅ Using cached icon configuration');
      } else {
        finalIconConfig = _getConfigurationIcons();
        print('✅ Using configuration service icons');
      }

      _iconConfig = finalIconConfig;
      _iconMappings = _parseIconMappings(finalIconConfig);
      _iconStyles = _parseIconStyles(finalIconConfig);
      _isLoaded = true;

      print('🎯 Dynamic icons loaded successfully');
    } catch (e) {
      print('❌ Error loading dynamic icons: $e');
      _iconMappings = _getDefaultIconMappings();
      _iconStyles = {};
      _isLoaded = true;
    }
  }

  Future<Map<String, dynamic>?> _fetchRemoteIconConfig(String token) async {
    try {
      final response = await ApiService.instance.callCustomAPI(
        'local_instructohub_get_icon_config',
        token,
        {},
        method: 'GET',
      );

      if (response != null && response is Map) {
        return Map<String, dynamic>.from(response);
      }
    } catch (e) {
      print('Failed to fetch remote icon config: $e');
    }
    return null;
  }

  Map<String, dynamic> _getConfigurationIcons() {
    final config = ConfigurationService.instance.currentConfig;
    if (config != null) {
      return {
        'icons': config.iconMappings,
        'styles': {},
        'source': 'configuration_service',
        'last_updated': DateTime.now().toIso8601String(),
      };
    }
    return _getDefaultIconConfig();
  }

  Map<String, dynamic> _getDefaultIconConfig() {
    return {
      'icons': {
        'home': 'home_outlined',
        'dashboard': 'dashboard_outlined',
        'courses': 'book_outlined',
        'assignments': 'assignment_outlined',
        'grades': 'grade',
        'calendar': 'event_outlined',
        'messages': 'chat_outlined',
        'notifications': 'notifications_outlined',
        'profile': 'person_outline',
        'person': 'person_outline',
        'settings': 'settings_outlined',
        'logout': 'logout',
        'search': 'search',
        'menu': 'menu',
        'back': 'arrow_back_ios',
        'forward': 'arrow_forward_ios',
        'play': 'play_circle_outline',
        'pause': 'pause',
        'download': 'cloud_download',
        'upload': 'cloud_upload',
        'share': 'share_outlined',
        'favorite': 'favorite_outline',
        'bookmark': 'bookmark_outline',
        'edit': 'edit',
        'delete': 'delete',
        'add': 'add',
        'check': 'check_circle_outline',
        'close': 'close',
        'info': 'info_outline',
        'warning': 'warning_outlined',
        'error': 'error_outline',
        'success': 'check_circle',
        'help': 'help_outline',
        'visibility_on': 'visibility_outlined',
        'visibility_off': 'visibility_off_outlined',
        'lock': 'lock_outline',
        'star': 'star_outlined',
        'chart': 'show_chart',
        'analytics': 'analytics_outlined',
        'history': 'history_outlined',
        'refresh': 'refresh',
        'sync': 'sync',
        'language': 'language',
        'theme': 'palette',
        'brightness': 'brightness_6',
        'wifi': 'wifi',
        'cloud': 'cloud_outlined',
        'folder': 'folder',
        'file': 'description',
        'image': 'image',
        'video': 'video_library',
        'audio': 'library_music',
        'attach': 'attach_file',
        'link': 'link',
        'copy': 'content_copy',
        'filter': 'filter_list',
        'sort': 'sort',
        'more': 'more_vert',
        'expand': 'expand_more',
        'collapse': 'expand_less',
        'users': 'people_outline',
        'group': 'groups',
        'admin': 'admin_panel_settings',
        'badge': 'workspace_premium',
        'achievement': 'emoji_events',
        'progress': 'timeline',
        'time': 'schedule',
        'location': 'location_on',
        'phone': 'phone',
        'email': 'mail_outline',
        'website': 'language',
        'document': 'article',
        'note': 'sticky_note_2',
        'category': 'category',
        'tag': 'label',
        'flag': 'flag',
        'domain': 'language',
        'school': 'school',
        'swap': 'sync',
      },
      'styles': {
        'default': 'outlined',
        'primary': 'filled',
        'secondary': 'outlined',
      },
      'source': 'default',
      'last_updated': DateTime.now().toIso8601String(),
    };
  }

  

  Map<String, IconData> _parseIconMappings(Map<String, dynamic> iconConfig) {
    final iconsMap = iconConfig['icons'] ?? {};
    final Map<String, IconData> parsedIcons = {};

    iconsMap.forEach((key, value) {
      if (value is String) {
        IconData? icon = _resolveIconFromString(value);
        if (icon != null) {
          parsedIcons[key] = icon;
        } else {
          print('⚠️ Unknown icon: $value for key: $key');
          parsedIcons[key] = Icons.help_outline;
        }
      }
    });

    final defaultMappings = _getDefaultIconMappings();
    defaultMappings.forEach((key, defaultIcon) {
      parsedIcons.putIfAbsent(key, () => defaultIcon);
    });

    return parsedIcons;
  }

  Map<String, String> _parseIconStyles(Map<String, dynamic> iconConfig) {
    final stylesMap = iconConfig['styles'] ?? {};
    return Map<String, String>.from(stylesMap);
  }

  IconData? _resolveIconFromString(String iconName) {
    String normalizedName = iconName.toLowerCase().trim();

    if (_legacyMapping.containsKey(normalizedName)) {
      normalizedName = _legacyMapping[normalizedName]!;
    }

    if (_materialIcons.containsKey(normalizedName)) {
      return _materialIcons[normalizedName];
    }

    for (String key in _materialIcons.keys) {
      if (key.contains(normalizedName) || normalizedName.contains(key)) {
        return _materialIcons[key];
      }
    }

    return null;
  }

  Map<String, IconData> _getDefaultIconMappings() {
    final defaultConfig = _getDefaultIconConfig();
    final Map<String, IconData> mappings = {};

    final iconsMap = defaultConfig['icons'] as Map<String, dynamic>;
    iconsMap.forEach((key, value) {
      IconData? icon = _resolveIconFromString(value as String);
      mappings[key] = icon ?? Icons.help_outline;
    });

    return mappings;
  }

  Future<Map<String, dynamic>?> _loadCachedIconConfig() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final cachedData = prefs.getString('dynamic_icons_v2');
      if (cachedData != null) {
        return Map<String, dynamic>.from(json.decode(cachedData));
      }
    } catch (e) {
      print('Error loading cached icon config: $e');
    }
    return null;
  }

  Future<void> _saveCachedIconConfig(Map<String, dynamic> iconConfig) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('dynamic_icons_v2', json.encode(iconConfig));
    } catch (e) {
      print('Error saving cached icon config: $e');
    }
  }

  IconData getIcon(String iconKey, {String? style}) {
    if (!_isLoaded) {
      return _getDefaultIconMappings()[iconKey] ?? Icons.help_outline;
    }

    IconData? icon = _iconMappings?[iconKey];

    if (icon == null) {
      IconData? resolvedIcon = _resolveIconFromString(iconKey);
      if (resolvedIcon != null) {
        icon = resolvedIcon;
      } else {
        icon = _getDefaultIconMappings()[iconKey] ?? Icons.help_outline;
      }
    }

    if (style != null) {
      String iconName = _getIconNameFromData(icon);
      if (iconName.isNotEmpty) {
        IconData? styledIcon = _getStyledIcon(iconName, style);
        if (styledIcon != null) {
          return styledIcon;
        }
      }
    }

    return icon;
  }

  String _getIconNameFromData(IconData iconData) {
    for (String key in _materialIcons.keys) {
      if (_materialIcons[key] == iconData) {
        return key;
      }
    }
    return '';
  }

  IconData? _getStyledIcon(String baseName, String style) {
    String styledName;

    switch (style.toLowerCase()) {
      case 'outlined':
      case 'outline':
        styledName = '${baseName}_outlined';
        break;
      case 'filled':
      case 'solid':
        styledName = baseName.replaceAll('_outlined', '');
        break;
      case 'rounded':
        styledName = '${baseName}_rounded';
        break;
      case 'sharp':
        styledName = '${baseName}_sharp';
        break;
      default:
        return null;
    }

    return _materialIcons[styledName];
  }

  List<String> getAvailableIcons() {
    return _materialIcons.keys.toList()..sort();
  }

  List<String> searchIcons(String query) {
    final lowercaseQuery = query.toLowerCase();
    return _materialIcons.keys
        .where((iconName) => iconName.contains(lowercaseQuery))
        .toList()
      ..sort();
  }

  bool hasIcon(String iconKey) {
    return _iconMappings?.containsKey(iconKey) ??
        false ||
            _materialIcons.containsKey(iconKey) ||
            _resolveIconFromString(iconKey) != null;
  }

  Map<String, dynamic> getIconDebugInfo() {
    return {
      'isLoaded': _isLoaded,
      'hasIconConfig': _iconConfig != null,
      'mappingsCount': _iconMappings?.length ?? 0,
      'stylesCount': _iconStyles?.length ?? 0,
      'source': _iconConfig?['source'] ?? 'unknown',
      'lastUpdated': _iconConfig?['last_updated'] ?? 'unknown',
      'totalAvailableIcons': _materialIcons.length,
      'sampleMappings': _iconMappings?.entries
              .take(5)
              .map((e) => '${e.key}: ${_getIconNameFromData(e.value)}')
              .toList() ??
          [],
    };
  }

  Future<void> clearIconCache() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('dynamic_icons_v2');
      _iconMappings = null;
      _iconStyles = null;
      _iconConfig = null;
      _isLoaded = false;
      print('Icon cache cleared');
    } catch (e) {
      print('Error clearing icon cache: $e');
    }
  }

  // Convenience getters for commonly used icons
  IconData get homeIcon => getIcon('home');
  IconData get dashboardIcon => getIcon('dashboard');
  IconData get coursesIcon => getIcon('courses');
  IconData get settingsIcon => getIcon('settings');
  IconData get profileIcon => getIcon('profile');
  IconData get personIcon => getIcon('person');
  IconData get logoutIcon => getIcon('logout');
  IconData get searchIcon => getIcon('search');
  IconData get menuIcon => getIcon('menu');
  IconData get backIcon => getIcon('back');
  IconData get forwardIcon => getIcon('forward');
  IconData get playIcon => getIcon('play');
  IconData get pauseIcon => getIcon('pause');
  IconData get downloadIcon => getIcon('download');
  IconData get uploadIcon => getIcon('upload');
  IconData get shareIcon => getIcon('share');
  IconData get favoriteIcon => getIcon('favorite');
  IconData get bookmarkIcon => getIcon('bookmark');
  IconData get editIcon => getIcon('edit');
  IconData get deleteIcon => getIcon('delete');
  IconData get addIcon => getIcon('add');
  IconData get checkIcon => getIcon('check');
  IconData get closeIcon => getIcon('close');
  IconData get infoIcon => getIcon('info');
  IconData get warningIcon => getIcon('warning');
  IconData get errorIcon => getIcon('error');
  IconData get successIcon => getIcon('success');
  IconData get helpIcon => getIcon('help');
  IconData get visibilityOnIcon => getIcon('visibility_on');
  IconData get visibilityOffIcon => getIcon('visibility_off');
  IconData get lockIcon => getIcon('lock');
  IconData get starIcon => getIcon('star');
  IconData get chartIcon => getIcon('chart');
  IconData get analyticsIcon => getIcon('analytics');
  IconData get historyIcon => getIcon('history');
  IconData get refreshIcon => getIcon('refresh');
  IconData get syncIcon => getIcon('sync');
  IconData get languageIcon => getIcon('language');
  IconData get themeIcon => getIcon('theme');
  IconData get brightnessIcon => getIcon('brightness');
  IconData get wifiIcon => getIcon('wifi');
  IconData get cloudIcon => getIcon('cloud');
  IconData get folderIcon => getIcon('folder');
  IconData get fileIcon => getIcon('file');
  IconData get imageIcon => getIcon('image');
  IconData get videoIcon => getIcon('video');
  IconData get audioIcon => getIcon('audio');
  IconData get attachIcon => getIcon('attach');
  IconData get linkIcon => getIcon('link');
  IconData get copyIcon => getIcon('copy');
  IconData get filterIcon => getIcon('filter');
  IconData get sortIcon => getIcon('sort');
  IconData get moreIcon => getIcon('more');
  IconData get expandIcon => getIcon('expand');
  IconData get collapseIcon => getIcon('collapse');
  IconData get usersIcon => getIcon('users');
  IconData get groupIcon => getIcon('group');
  IconData get adminIcon => getIcon('admin');
  IconData get badgeIcon => getIcon('badge');
  IconData get achievementIcon => getIcon('achievement');
  IconData get progressIcon => getIcon('progress');
  IconData get timeIcon => getIcon('time');
  IconData get locationIcon => getIcon('location');
  IconData get phoneIcon => getIcon('phone');
  IconData get emailIcon => getIcon('email');
  IconData get websiteIcon => getIcon('website');
  IconData get documentIcon => getIcon('document');
  IconData get noteIcon => getIcon('note');
  IconData get categoryIcon => getIcon('category');
  IconData get tagIcon => getIcon('tag');
  IconData get flagIcon => getIcon('flag');
  IconData get notificationsIcon => getIcon('notifications');
  IconData get calendarIcon => getIcon('calendar');
  IconData get messagesIcon => getIcon('messages');
  IconData get assignmentsIcon => getIcon('assignments');
  IconData get gradesIcon => getIcon('grades');
  IconData get domainIcon => getIcon('domain');
  IconData get schoolIcon => getIcon('school');
  IconData get swapIcon => getIcon('swap');
}
class SafeIconService {
  static IconData getIconSafely(String iconName) {
    try {
      return DynamicIconService.instance.getIcon(iconName);
    } catch (e) {
      // Fallback icons
      switch (iconName) {
        case 'analytics': return Icons.analytics;
        case 'copy': return Icons.copy;
        case 'check_circle': return Icons.check_circle;
        case 'error': return Icons.error;
        case 'info': return Icons.info;
        case 'lightbulb': return Icons.lightbulb;
        case 'play': return Icons.play_arrow;
        case 'assignment': return Icons.assignment;
        default: return Icons.help_outline;
      }
    }
  }
  
  static IconData get errorIcon => Icons.error;
  static IconData get successIcon => Icons.check_circle;
  static IconData get infoIcon => Icons.info;
}