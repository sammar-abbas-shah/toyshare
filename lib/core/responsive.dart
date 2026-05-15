import 'package:flutter/material.dart';

class Responsive {
  static double width(BuildContext context) => MediaQuery.of(context).size.width;
  static bool isMobile(BuildContext context) => width(context) < 650;
  static bool isTablet(BuildContext context) => width(context) >= 650 && width(context) < 1100;
  static bool isDesktop(BuildContext context) => width(context) >= 1100;
  static bool isWeb(BuildContext context) => !isMobile(context);

  static int gridCrossAxisCount(BuildContext context) {
    if (isMobile(context)) return 2;
    if (isTablet(context)) return 3;
    return 4;
  }

  static double formMaxWidth(BuildContext context) {
    if (isMobile(context)) return double.infinity;
    if (isTablet(context)) return 560;
    return 640;
  }

  static double contentMaxWidth(BuildContext context) {
    if (isMobile(context)) return double.infinity;
    if (isTablet(context)) return 760;
    return 1080;
  }

  static EdgeInsets pagePadding(BuildContext context) {
    if (isMobile(context)) return const EdgeInsets.symmetric(horizontal: 16, vertical: 16);
    if (isTablet(context)) return const EdgeInsets.symmetric(horizontal: 32, vertical: 20);
    return const EdgeInsets.symmetric(horizontal: 48, vertical: 24);
  }
}
