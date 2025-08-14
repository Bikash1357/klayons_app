import 'dart:ui';

import 'package:flutter/cupertino.dart';

class AppColors {
  AppColors._(); //its a private constructor.

  //primary colours - Used for buttons, highlights,error main app color.
  static const Color primaryOrange = Color(0xFFF15722);
  static const Color highlight = Color(0xFFCF4307);
  static const Color errorState = Color(0xFFE03B38);

  //used in when something sucessfully done
  static const Color acceptState = Color(0xFF1DB812);

  //Background & Surface Colors - Used for page background (Scaffold), cards, containers, etc.
  static const Color background = Color(0xFFFFF7F1);
  static const Color primaryContainer = Color(0xFFFFFFFF);
  static const Color secondaryContainer = Color(0xFFF6F6F6);
  static const Color orangeHighlight = Color(0xFFFFD4C1);

  //Text Colors - Used for text elements. textOnPrimary is white—used on colored backgrounds like buttons.
  static const Color textPrimary = Color(0xFF130E01);
  static const Color textSecondary = Color(0xFF868686);
  static const Color textInactive = Color(0xFFA6A6A6);

  //Accent Colors - Used for icons, links, focus states, etc.
  static const Color darkElements = Color(0xFF433C39);
}
