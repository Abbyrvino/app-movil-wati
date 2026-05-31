import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTextStyles {
  static TextStyle h1 = GoogleFonts.poppins(fontSize: 28, fontWeight: FontWeight.bold, height: 1.28);
  static TextStyle h2 = GoogleFonts.poppins(fontSize: 22, fontWeight: FontWeight.w600, height: 1.27);
  static TextStyle h3 = GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.w600, height: 1.33);
  static TextStyle bodyLarge = GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.normal, height: 1.5);
  static TextStyle bodyMedium = GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.normal, height: 1.42);
  static TextStyle bodySmall = GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w500, height: 1.33);
  static TextStyle bigNumber = GoogleFonts.inter(fontSize: 36, fontWeight: FontWeight.bold, height: 1.11);
  static TextStyle button = GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.w600, height: 1.5);

  const AppTextStyles._();
}