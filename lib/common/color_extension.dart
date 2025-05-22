import 'package:flutter/material.dart';

class TColor {
  static Color get primaryColor1 => const Color.fromARGB(255, 255, 40, 122);
  static Color get primaryColor2 => const Color.fromARGB(255, 255, 171, 219);

  static Color get secondaryColor1 => const Color(0xffC58BF2);
  static Color get secondaryColor2 => const Color(0xffEEA4CE);

  static List<Color> get primaryG => [primaryColor1, primaryColor2];
  static List<Color> get secondaryG => [secondaryColor1, secondaryColor2];

  static Color get black => const Color(0xff1D1617);
  static Color get gray => const Color(0xff786F72);
  static Color get white => Colors.white;
  static Color get lightGray => const Color(0xffF7F8F8);
}