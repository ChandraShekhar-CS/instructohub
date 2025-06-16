import 'package:flutter/material.dart';

class AppTheme {
  // ----------------- FONT SIZES -----------------
  // Corresponds to the fontSize object from your JS theme
  static const double fontSize2xs = 10.0;
  static const double fontSizeXs = 12.0;
  static const double fontSizeSm = 14.0;
  static const double fontSizeBase = 16.0;
  static const double fontSizeLg = 18.0;
  static const double fontSizeXl = 20.0;
  static const double fontSize2xl = 24.0;

  // ----------------- THEME COLORS -----------------
  // Corresponds to the colors object from your JS theme
  // Primary Text Colors
  static const Color primary1 = Color(0xFF1f2937); // blacktext
  static const Color primary2 = Color(0xFF6b7280); // graytext
  static const Color primary3 = Color(0xFF000000);

  // General Colors
  static const Color offwhite = Color(0xFFFFFFFF);
  static const Color btnText = Color(0xFFFFFFFF);

  // Navigation Colors
  static const Color navbg = Color(0xFF1B3943);
  static const Color navselected = Color(0xFFE16B3A);
  static const Color navicon = Color(0xFFFFFFFF);
  static const Color navtext = Color(0xFFFFFFFF);
  static const Color naviconActive = Color(0xFFFFFFFF);
  static const Color navtextActive = Color(0xFFFFFFFF);

  // Secondary/Accent Colors
  static const Color secondary1 = Color(0xFFE16B3A); // orange
  static const Color secondary2 = Color(0xFF1B3943); // Green
  static const Color secondary3 = Color(0xFFFBECE6); // light orange

  // Login Screen Specific Colors
  static const Color loginBgLeft = Color(0xFFF7F7F7);
  static const Color loginBgRight = Color(0xFFFFFFFF);
  static const Color loginTextTitle = Color(0xFF1F2937);
  static const Color loginTextBody = Color(0xFF6B7280);
  static const Color loginButtonBg = Color(0xFFE16B3A);
  static const Color loginButtonHover = Color(0xFF1B3943);
  static const Color loginIconBg = Color(0xFFE16B3A);
  static const Color loginTextLink = Color(0xFF1F2937);
  static const Color loginTextLinkHover = Color(0xFF6B7280);
  static const Color loginButtonTextColor = Color(0xFFFFFFFF);

  // Old color names kept for compatibility, mapped to new values
  static const Color backgroundColor = loginBgLeft;
  static const Color cardColor = offwhite;
  static const Color textSecondary = primary2;

  // ----------------- GLOBAL THEME DATA -----------------
  static ThemeData get lightTheme {
    return ThemeData(
      primarySwatch: Colors.orange,
      primaryColor: secondary1,
      scaffoldBackgroundColor: backgroundColor,
      fontFamily: 'Inter',

      appBarTheme: const AppBarTheme(
        backgroundColor: backgroundColor,
        elevation: 0,
        iconTheme: IconThemeData(color: primary1),
        titleTextStyle: TextStyle(
          color: primary1,
          fontSize: fontSizeXl,
          fontWeight: FontWeight.bold,
          fontFamily: 'Inter',
        ),
      ),

      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: loginButtonBg,
          foregroundColor: loginButtonTextColor,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8.0),
          ),
          elevation: 2,
          textStyle: const TextStyle(
            fontWeight: FontWeight.w600,
            fontFamily: 'Inter',
            fontSize: fontSizeBase,
          ),
        ),
      ),

      cardTheme: CardThemeData(
        color: cardColor,
        elevation: 4,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12.0),
        ),
        shadowColor: Colors.black.withOpacity(0.1),
      ),

      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: cardColor,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8.0),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8.0),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder( // FIX: Removed 'const' keyword here
          borderRadius: BorderRadius.circular(8.0),
          borderSide: const BorderSide(color: secondary1, width: 2),
        ),
        contentPadding:
            const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
        hintStyle: const TextStyle(color: primary2),
      ),

      textTheme: const TextTheme(
        headlineLarge: TextStyle(
          color: primary1,
          fontWeight: FontWeight.bold,
          fontFamily: 'Inter',
          fontSize: fontSize2xl,
        ),
        headlineMedium: TextStyle(
          color: primary1,
          fontWeight: FontWeight.bold,
          fontFamily: 'Inter',
          fontSize: fontSizeXl,
        ),
        titleLarge: TextStyle(
          color: primary1,
          fontWeight: FontWeight.bold,
          fontFamily: 'Inter',
          fontSize: fontSizeLg,
        ),
        titleMedium: TextStyle(
          color: primary1,
          fontWeight: FontWeight.w600,
          fontFamily: 'Inter',
          fontSize: fontSizeBase,
        ),
        bodyLarge: TextStyle(
          color: primary1,
          fontFamily: 'Inter',
          fontSize: fontSizeBase,
        ),
        bodyMedium: TextStyle(
          color: primary2,
          fontFamily: 'Inter',
          fontSize: fontSizeSm,
        ),
      ),

      iconTheme: const IconThemeData(
        color: secondary1,
      ),

      dividerTheme: DividerThemeData(
        color: Colors.grey.shade300,
        thickness: 1,
      ),

      checkboxTheme: CheckboxThemeData(
        fillColor: MaterialStateProperty.resolveWith((states) {
          if (states.contains(MaterialState.selected)) {
            return secondary1;
          }
          return Colors.transparent;
        }),
        checkColor: MaterialStateProperty.all(cardColor),
        side: const BorderSide(color: secondary1, width: 2),
      ),
    );
  }

  // ----------------- DECORATIONS -----------------
  // Kept for consistent styling of custom widgets
  static BoxDecoration get cardDecoration {
    return BoxDecoration(
      color: cardColor,
      borderRadius: BorderRadius.circular(12.0),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withOpacity(0.08),
          spreadRadius: 1,
          blurRadius: 10,
          offset: const Offset(0, 2),
        ),
      ],
    );
  }

  static BoxDecoration get inputDecoration {
    return BoxDecoration(
      color: cardColor,
      borderRadius: BorderRadius.circular(8.0),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withOpacity(0.05),
          spreadRadius: 1,
          blurRadius: 10,
          offset: const Offset(0, 2),
        ),
      ],
    );
  }
}