import 'package:flutter/material.dart';

const Color primaryColor= Color(0xFFFF8A00);
const Color secondPrimaryColor= Color(0XFF5BAB3B);

Color borderColor= Colors.grey.withOpacity(0.18);
const Color containerColor= Color(0xFFF9FAFB);

const Color primaryTextColor= Color(0xFF111827);
const Color secondPrimaryTextColor= Color(0xFF6B7280);

class ThemeService {

  final lightTheme = ThemeData(
    scaffoldBackgroundColor:  Color(0xFFFFFFFF),

    primaryColor: primaryColor,
    fontFamily: 'Cairo',
    brightness: Brightness.light,
    bottomNavigationBarTheme: BottomNavigationBarThemeData(
        selectedItemColor: primaryColor,
        showUnselectedLabels: false
    ),
    buttonTheme: const ButtonThemeData(
        colorScheme: ColorScheme.dark(),
        buttonColor: Colors.black87
    ),
    tabBarTheme: TabBarTheme(
      labelColor: Colors.black87,
      dividerColor: primaryColor,
    ),
  );
}