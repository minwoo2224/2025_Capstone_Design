import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

ThemeData buildGameTheme() {
  return ThemeData(
    brightness: Brightness.dark,
    scaffoldBackgroundColor: const Color(0xFF1A1A2E),
    appBarTheme: AppBarTheme(
      backgroundColor: const Color(0xFF0F3460),
      titleTextStyle: GoogleFonts.orbitron(
        fontSize: 16,
        color: Colors.amberAccent,
        fontWeight: FontWeight.bold,
      ).copyWith(fontFamilyFallback: ['Noto Sans KR']),
      centerTitle: true,
    ),
    textTheme: GoogleFonts.orbitronTextTheme().copyWith(
      bodyMedium: GoogleFonts.orbitron(
        fontSize: 13,
        color: Colors.amber.shade200,
        fontWeight: FontWeight.w600,
      ).copyWith(fontFamilyFallback: ['Noto Sans KR']),
      bodySmall: GoogleFonts.orbitron(
        fontSize: 11,
        color: Colors.amber.shade100,
        fontWeight: FontWeight.w400,
      ).copyWith(fontFamilyFallback: ['Noto Sans KR']),
    ),
    floatingActionButtonTheme: const FloatingActionButtonThemeData(
      backgroundColor: Colors.amber,
      foregroundColor: Colors.black,
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.deepPurple.shade600,
        foregroundColor: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        textStyle: GoogleFonts.orbitron(
          fontSize: 11,
          fontWeight: FontWeight.w500,
        ).copyWith(fontFamilyFallback: ['Noto Sans KR']),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      ),
    ),
    cardColor: Colors.deepPurple.shade900.withOpacity(0.9),
    cardTheme: const CardThemeData(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.all(Radius.circular(15)),
        side: BorderSide(color: Color(0xFFFFECB3), width: 1.5),
      ),
      elevation: 8,
      margin: EdgeInsets.all(10),
    ),
  );
}
