// File: lib/theme/dynamic_app_theme.dart
// REPLACE your existing app_theme.dart with this dynamic version

import 'package:flutter/material.dart';
import '../services/dynamic_theme_service.dart';
import '../services/enhanced_icon_service.dart';

class DynamicAppTheme {
  static DynamicThemeService get _themeService => DynamicThemeService.instance;
  static DynamicIconService get _iconService => DynamicIconService.instance;

  // Dynamic color getters
  static Color get primary1 => _themeService.getColor('primary1');
  static Color get primary2 => _themeService.getColor('primary2');
  static Color get primary3 => _themeService.getColor('primary3');
  static Color get secondary1 => _themeService.getColor('secondary1');
  static Color get secondary2 => _themeService.getColor('secondary2');
  static Color get secondary3 => _themeService.getColor('secondary3');
  static Color get background => _themeService.getColor('background');
  static Color get cardColor => _themeService.getColor('cardColor');
  static Color get textPrimary => _themeService.getColor('textPrimary');
  static Color get textSecondary => _themeService.getColor('textSecondary');
  static Color get success => _themeService.getColor('success');
  static Color get warning => _themeService.getColor('warning');
  static Color get error => _themeService.getColor('error');
  static Color get info => _themeService.getColor('info');

  // Legacy color compatibility (maps to new dynamic colors)
  static Color get offwhite => cardColor;
  static Color get btnText => Colors.white;
  static Color get navbg => secondary2;
  static Color get navselected => secondary1;
  static Color get navicon => Colors.white;
  static Color get navtext => Colors.white;
  static Color get naviconActive => Colors.white;
  static Color get navtextActive => Colors.white;
  static Color get loginBgLeft => background;
  static Color get loginBgRight => cardColor;
  static Color get loginTextTitle => textPrimary;
  static Color get loginTextBody => textSecondary;
  static Color get loginButtonBg => secondary1;
  static Color get loginButtonHover => secondary2;
  static Color get loginIconBg => secondary1;
  static Color get loginTextLink => textPrimary;
  static Color get loginTextLinkHover => textSecondary;
  static Color get loginButtonTextColor => Colors.white;
  static Color get backgroundColor => background;

  // Dynamic spacing getters
  static double get spacingXs => _themeService.getSpacing('xs');
  static double get spacingSm => _themeService.getSpacing('sm');
  static double get spacingMd => _themeService.getSpacing('md');
  static double get spacingLg => _themeService.getSpacing('lg');
  static double get spacingXl => _themeService.getSpacing('xl');

  // Dynamic border radius getters
  static double get radiusSmall => _themeService.getBorderRadius('small');
  static double get radiusMedium => _themeService.getBorderRadius('medium');
  static double get radiusLarge => _themeService.getBorderRadius('large');
  static double get radiusXl => _themeService.getBorderRadius('xl');

  // Dynamic elevation getters
  static double get elevationLow => _themeService.getElevation('low');
  static double get elevationMedium => _themeService.getElevation('medium');
  static double get elevationHigh => _themeService.getElevation('high');

  // Legacy font size constants (can be made dynamic later)
  static const double fontSize2xs = 10.0;
  static const double fontSizeXs = 12.0;
  static const double fontSizeSm = 14.0;
  static const double fontSizeBase = 16.0;
  static const double fontSizeLg = 18.0;
  static const double fontSizeXl = 20.0;
  static const double fontSize2xl = 24.0;

  // Main theme getter - returns the current dynamic theme
  static ThemeData get lightTheme => _themeService.currentTheme;

  // Dynamic decorations
  static BoxDecoration get cardDecoration => _themeService.getDynamicCardDecoration();
  static BoxDecoration get inputDecoration => _themeService.getDynamicInputDecoration();

  // Custom gradient decorations
  static BoxDecoration get primaryGradientDecoration {
    return BoxDecoration(
      gradient: LinearGradient(
        colors: [secondary1, secondary2],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ),
      borderRadius: BorderRadius.circular(radiusMedium),
      boxShadow: [
        BoxShadow(
          color: secondary1.withOpacity(0.3),
          spreadRadius: 0,
          blurRadius: elevationMedium * 2,
          offset: const Offset(0, 2),
        ),
      ],
    );
  }

  static BoxDecoration get secondaryGradientDecoration {
    return BoxDecoration(
      gradient: LinearGradient(
        colors: [secondary2, secondary1],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ),
      borderRadius: BorderRadius.circular(radiusMedium),
      boxShadow: [
        BoxShadow(
          color: secondary2.withOpacity(0.3),
          spreadRadius: 0,
          blurRadius: elevationMedium * 2,
          offset: const Offset(0, 2),
        ),
      ],
    );
  }

  static BoxDecoration get backgroundGradientDecoration {
    return BoxDecoration(
      gradient: LinearGradient(
        colors: [background, cardColor],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ),
    );
  }

  // Dynamic button styles
  static ButtonStyle get primaryButtonStyle {
    return ElevatedButton.styleFrom(
      backgroundColor: secondary1,
      foregroundColor: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(radiusMedium),
      ),
      elevation: elevationMedium,
      padding: EdgeInsets.symmetric(
        vertical: spacingMd,
        horizontal: spacingLg,
      ),
      textStyle: const TextStyle(
        fontWeight: FontWeight.w600,
        fontSize: fontSizeBase,
      ),
    );
  }

  static ButtonStyle get secondaryButtonStyle {
    return ElevatedButton.styleFrom(
      backgroundColor: secondary2,
      foregroundColor: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(radiusMedium),
      ),
      elevation: elevationMedium,
      padding: EdgeInsets.symmetric(
        vertical: spacingMd,
        horizontal: spacingLg,
      ),
      textStyle: const TextStyle(
        fontWeight: FontWeight.w600,
        fontSize: fontSizeBase,
      ),
    );
  }

  static ButtonStyle get outlinedButtonStyle {
    return OutlinedButton.styleFrom(
      foregroundColor: secondary1,
      side: BorderSide(color: secondary1, width: 2),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(radiusMedium),
      ),
      padding: EdgeInsets.symmetric(
        vertical: spacingMd,
        horizontal: spacingLg,
      ),
      textStyle: const TextStyle(
        fontWeight: FontWeight.w600,
        fontSize: fontSizeBase,
      ),
    );
  }

  static ButtonStyle get textButtonStyle {
    return TextButton.styleFrom(
      foregroundColor: secondary1,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(radiusSmall),
      ),
      padding: EdgeInsets.symmetric(
        vertical: spacingSm,
        horizontal: spacingMd,
      ),
      textStyle: const TextStyle(
        fontWeight: FontWeight.w500,
        fontSize: fontSizeBase,
      ),
    );
  }

  // Dynamic input decoration theme
  static InputDecorationTheme get inputDecorationTheme {
    return InputDecorationTheme(
      filled: true,
      fillColor: cardColor,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(radiusMedium),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(radiusMedium),
        borderSide: BorderSide(color: textSecondary.withOpacity(0.3)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(radiusMedium),
        borderSide: BorderSide(color: secondary1, width: 2),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(radiusMedium),
        borderSide: BorderSide(color: error, width: 2),
      ),
      contentPadding: EdgeInsets.symmetric(
        vertical: spacingMd,
        horizontal: spacingMd,
      ),
      hintStyle: TextStyle(color: textSecondary),
      labelStyle: TextStyle(color: textSecondary),
    );
  }

  // Dynamic card theme
  static CardTheme get cardTheme {
    return CardTheme(
      color: cardColor,
      elevation: elevationMedium,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(radiusMedium),
      ),
      shadowColor: Colors.black.withOpacity(0.1),
      margin: EdgeInsets.all(spacingSm),
    );
  }

  // Dynamic app bar theme
  static AppBarTheme get appBarTheme {
    return AppBarTheme(
      backgroundColor: background,
      elevation: elevationLow,
      iconTheme: IconThemeData(color: textPrimary),
      titleTextStyle: TextStyle(
        color: textPrimary,
        fontSize: fontSizeXl,
        fontWeight: FontWeight.bold,
      ),
      centerTitle: false,
    );
  }

  // Dynamic chip theme
  static ChipThemeData get chipTheme {
    return ChipThemeData(
      backgroundColor: secondary3,
      labelStyle: TextStyle(color: secondary1),
      padding: EdgeInsets.all(spacingSm),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(radiusLarge),
      ),
    );
  }

  // Dynamic snackbar theme
  static SnackBarThemeData get snackBarTheme {
    return SnackBarThemeData(
      backgroundColor: secondary2,
      contentTextStyle: const TextStyle(color: Colors.white),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(radiusMedium),
      ),
      behavior: SnackBarBehavior.floating,
    );
  }

  // Custom widget styles
  static BoxDecoration getStatusDecoration(String status) {
    Color statusColor;
    switch (status.toLowerCase()) {
      case 'success':
      case 'completed':
      case 'done':
        statusColor = success;
        break;
      case 'warning':
      case 'pending':
      case 'in_progress':
        statusColor = warning;
        break;
      case 'error':
      case 'failed':
      case 'cancelled':
        statusColor = error;
        break;
      case 'info':
      case 'draft':
      default:
        statusColor = info;
        break;
    }

    return BoxDecoration(
      color: statusColor.withOpacity(0.1),
      borderRadius: BorderRadius.circular(radiusSmall),
      border: Border.all(color: statusColor.withOpacity(0.3)),
    );
  }

  static TextStyle getStatusTextStyle(String status) {
    Color statusColor;
    switch (status.toLowerCase()) {
      case 'success':
      case 'completed':
      case 'done':
        statusColor = success;
        break;
      case 'warning':
      case 'pending':
      case 'in_progress':
        statusColor = warning;
        break;
      case 'error':
      case 'failed':
      case 'cancelled':
        statusColor = error;
        break;
      case 'info':
      case 'draft':
      default:
        statusColor = info;
        break;
    }

    return TextStyle(
      color: statusColor,
      fontWeight: FontWeight.w600,
      fontSize: fontSizeSm,
    );
  }

  // Priority/importance based styles
  static BoxDecoration getImportanceDecoration(String importance) {
    Color importanceColor;
    switch (importance.toLowerCase()) {
      case 'high':
      case 'urgent':
      case 'critical':
        importanceColor = error;
        break;
      case 'medium':
      case 'normal':
        importanceColor = warning;
        break;
      case 'low':
        importanceColor = info;
        break;
      default:
        importanceColor = textSecondary;
        break;
    }

    return BoxDecoration(
      color: importanceColor.withOpacity(0.1),
      borderRadius: BorderRadius.circular(radiusSmall),
      border: Border.all(color: importanceColor.withOpacity(0.5)),
    );
  }

  // Utility methods for theme management
  static Future<void> loadTheme({String? token}) async {
    await _themeService.loadTheme(token: token);
    await _iconService.loadIcons(token: token);
  }

  static Future<void> clearThemeCache() async {
    await _themeService.clearThemeCache();
    await _iconService.clearIconCache();
  }

  static bool get isThemeLoaded => _themeService.isLoaded && _iconService.isLoaded;

  static Map<String, dynamic> getThemeDebugInfo() {
    return {
      'theme': _themeService.getThemeDebugInfo(),
      'icons': _iconService.getIconDebugInfo(),
    };
  }

  // Helper methods for common UI patterns
  static Widget buildLoadingIndicator({Color? color, double size = 24.0}) {
    return SizedBox(
      width: size,
      height: size,
      child: CircularProgressIndicator(
        color: color ?? secondary1,
        strokeWidth: 2,
      ),
    );
  }

  static Widget buildStatusChip(String status, String label) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: spacingMd,
        vertical: spacingSm,
      ),
      decoration: getStatusDecoration(status),
      child: Text(
        label,
        style: getStatusTextStyle(status),
      ),
    );
  }

  static Widget buildGradientContainer({
    required Widget child,
    List<Color>? colors,
    double? borderRadius,
    EdgeInsetsGeometry? padding,
    EdgeInsetsGeometry? margin,
  }) {
    return Container(
      padding: padding ?? EdgeInsets.all(spacingMd),
      margin: margin,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: colors ?? [secondary1, secondary2],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(borderRadius ?? radiusMedium),
        boxShadow: [
          BoxShadow(
            color: (colors?.first ?? secondary1).withOpacity(0.3),
            spreadRadius: 0,
            blurRadius: elevationMedium * 2,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: child,
    );
  }

  static Widget buildIconButton({
    required String iconKey,
    required VoidCallback onPressed,
    String? tooltip,
    Color? color,
    Color? backgroundColor,
    double? size,
    EdgeInsetsGeometry? padding,
  }) {
    return Container(
      decoration: backgroundColor != null
          ? BoxDecoration(
              color: backgroundColor,
              borderRadius: BorderRadius.circular(radiusSmall),
              boxShadow: [
                BoxShadow(
                  color: backgroundColor.withOpacity(0.3),
                  spreadRadius: 0,
                  blurRadius: elevationLow * 2,
                  offset: const Offset(0, 1),
                ),
              ],
            )
          : null,
      child: IconButton(
        onPressed: onPressed,
        icon: Icon(
          _iconService.getIcon(iconKey),
          color: color ?? secondary1,
          size: size ?? 24,
        ),
        tooltip: tooltip,
        padding: padding ?? EdgeInsets.all(spacingSm),
      ),
    );
  }

  static Widget buildActionButton({
    required String text,
    required VoidCallback onPressed,
    String? iconKey,
    ButtonStyle? style,
    bool isLoading = false,
    bool isEnabled = true,
  }) {
    Widget buttonChild;
    
    if (isLoading) {
      buttonChild = buildLoadingIndicator(color: Colors.white, size: 20);
    } else if (iconKey != null) {
      buttonChild = Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(_iconService.getIcon(iconKey), size: 20),
          SizedBox(width: spacingSm),
          Text(text),
        ],
      );
    } else {
      buttonChild = Text(text);
    }

    return ElevatedButton(
      onPressed: isEnabled && !isLoading ? onPressed : null,
      style: style ?? primaryButtonStyle,
      child: buttonChild,
    );
  }

  static Widget buildInfoCard({
    required String title,
    String? subtitle,
    String? iconKey,
    Widget? trailing,
    VoidCallback? onTap,
    Color? iconColor,
  }) {
    return Card(
      child: ListTile(
        leading: iconKey != null
            ? Container(
                padding: EdgeInsets.all(spacingSm),
                decoration: BoxDecoration(
                  color: (iconColor ?? secondary1).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(radiusSmall),
                ),
                child: Icon(
                  _iconService.getIcon(iconKey),
                  color: iconColor ?? secondary1,
                  size: 24,
                ),
              )
            : null,
        title: Text(
          title,
          style: TextStyle(
            fontWeight: FontWeight.w600,
            color: textPrimary,
          ),
        ),
        subtitle: subtitle != null
            ? Text(
                subtitle,
                style: TextStyle(color: textSecondary),
              )
            : null,
        trailing: trailing,
        onTap: onTap,
      ),
    );
  }

  static Widget buildStatCard({
    required String title,
    required String value,
    String? iconKey,
    Color? color,
    String? subtitle,
  }) {
    final cardColor = color ?? secondary1;
    
    return Card(
      child: Padding(
        padding: EdgeInsets.all(spacingLg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                if (iconKey != null) ...[
                  Container(
                    padding: EdgeInsets.all(spacingSm),
                    decoration: BoxDecoration(
                      color: cardColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(radiusSmall),
                    ),
                    child: Icon(
                      _iconService.getIcon(iconKey),
                      color: cardColor,
                      size: 24,
                    ),
                  ),
                  SizedBox(width: spacingMd),
                ],
                Expanded(
                  child: Text(
                    title,
                    style: TextStyle(
                      fontSize: fontSizeSm,
                      color: textSecondary,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
            SizedBox(height: spacingSm),
            Text(
              value,
              style: TextStyle(
                fontSize: fontSize2xl,
                fontWeight: FontWeight.bold,
                color: textPrimary,
              ),
            ),
            if (subtitle != null) ...[
              SizedBox(height: spacingXs),
              Text(
                subtitle,
                style: TextStyle(
                  fontSize: fontSizeXs,
                  color: textSecondary,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  static Widget buildProgressCard({
    required String title,
    required double progress,
    String? subtitle,
    Color? progressColor,
  }) {
    final color = progressColor ?? secondary1;
    
    return Card(
      child: Padding(
        padding: EdgeInsets.all(spacingLg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: TextStyle(
                fontSize: fontSizeLg,
                fontWeight: FontWeight.bold,
                color: textPrimary,
              ),
            ),
            if (subtitle != null) ...[
              SizedBox(height: spacingXs),
              Text(
                subtitle,
                style: TextStyle(
                  fontSize: fontSizeSm,
                  color: textSecondary,
                ),
              ),
            ],
            SizedBox(height: spacingMd),
            ClipRRect(
              borderRadius: BorderRadius.circular(radiusSmall),
              child: LinearProgressIndicator(
                value: progress / 100,
                backgroundColor: textSecondary.withOpacity(0.2),
                valueColor: AlwaysStoppedAnimation<Color>(color),
                minHeight: 8,
              ),
            ),
            SizedBox(height: spacingSm),
            Text(
              '${progress.toStringAsFixed(1)}% Complete',
              style: TextStyle(
                fontSize: fontSizeSm,
                color: textSecondary,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  static AppBar buildDynamicAppBar({
    required String title,
    List<Widget>? actions,
    Widget? leading,
    bool centerTitle = false,
    Color? backgroundColor,
    Color? foregroundColor,
    double? elevation,
  }) {
    return AppBar(
      title: Text(title),
      centerTitle: centerTitle,
      backgroundColor: backgroundColor ?? background,
      foregroundColor: foregroundColor ?? textPrimary,
      elevation: elevation ?? elevationLow,
      leading: leading,
      actions: actions,
    );
  }

  static BottomNavigationBar buildDynamicBottomNav({
    required int currentIndex,
    required List<BottomNavigationBarItem> items,
    required Function(int) onTap,
  }) {
    return BottomNavigationBar(
      currentIndex: currentIndex,
      onTap: onTap,
      type: BottomNavigationBarType.fixed,
      backgroundColor: navbg,
      selectedItemColor: navselected,
      unselectedItemColor: navicon.withOpacity(0.6),
      items: items,
    );
  }

  static Drawer buildDynamicDrawer({
    required List<Widget> children,
    String? headerTitle,
    String? headerSubtitle,
    Widget? headerChild,
  }) {
    return Drawer(
      child: Column(
        children: [
          if (headerChild != null)
            headerChild
          else
            DrawerHeader(
              decoration: primaryGradientDecoration,
              child: Container(
                width: double.infinity,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    if (headerTitle != null)
                      Text(
                        headerTitle,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: fontSize2xl,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    if (headerSubtitle != null) ...[
                      SizedBox(height: spacingXs),
                      Text(
                        headerSubtitle,
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.8),
                          fontSize: fontSizeBase,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          Expanded(
            child: ListView(
              padding: EdgeInsets.zero,
              children: children,
            ),
          ),
        ],
      ),
    );
  }

  static ListTile buildDrawerItem({
    required String title,
    required String iconKey,
    VoidCallback? onTap,
    bool isSelected = false,
    String? subtitle,
  }) {
    return ListTile(
      leading: Icon(
        _iconService.getIcon(iconKey),
        color: isSelected ? navselected : navicon,
      ),
      title: Text(
        title,
        style: TextStyle(
          color: isSelected ? navselected : navtext,
          fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
        ),
      ),
      subtitle: subtitle != null
          ? Text(
              subtitle,
              style: TextStyle(
                color: (isSelected ? navselected : navtext).withOpacity(0.7),
                fontSize: fontSizeSm,
              ),
            )
          : null,
      selected: isSelected,
      selectedTileColor: navselected.withOpacity(0.1),
      onTap: onTap,
    );
  }

  // Theme transition animations
  static Widget buildThemeTransition({
    required Widget child,
    Duration duration = const Duration(milliseconds: 300),
  }) {
    return AnimatedSwitcher(
      duration: duration,
      transitionBuilder: (Widget child, Animation<double> animation) {
        return FadeTransition(
          opacity: animation,
          child: child,
        );
      },
      child: Container(
        key: ValueKey(_themeService.isLoaded),
        child: child,
      ),
    );
  }
}