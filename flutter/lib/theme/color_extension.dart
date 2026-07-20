import 'package:flutter/material.dart';

import 'app_theme.dart';

class ColorThemeExtension extends ThemeExtension<ColorThemeExtension> {
  const ColorThemeExtension({
    required this.border,
    required this.border2,
    required this.border3,
    required this.highlight,
    required this.drag_indicator,
    required this.shadow,
    required this.errorBannerBg,
    required this.me,
    required this.toastBg,
    required this.toastText,
    required this.divider,
  });

  final Color? border;
  final Color? border2;
  final Color? border3;
  final Color? highlight;
  final Color? drag_indicator;
  final Color? shadow;
  final Color? errorBannerBg;
  final Color? me;
  final Color? toastBg;
  final Color? toastText;
  final Color? divider;

  static final light = ColorThemeExtension(
    border: Color(0xFFE5E7EB),
    border2: Color(0xFFBBBBBB),
    border3: Colors.black26,
    highlight: Color(0xFFF0F2F5),
    drag_indicator: Colors.grey[800],
    shadow: Colors.black,
    errorBannerBg: Color(0xFFFDEEEB),
    me: Colors.green,
    toastBg: Colors.black.withOpacity(0.6),
    toastText: Colors.white,
    divider: Color(0xFFEFF0F1),
  );

  static final dark = ColorThemeExtension(
    border: Color(0xFF2A3346),
    border2: Color(0xFFE5E5E5),
    border3: Colors.white24,
    highlight: Color(0xFF242D40),
    drag_indicator: Colors.grey,
    shadow: Colors.grey,
    errorBannerBg: Color(0xFF470F2D),
    me: Colors.greenAccent,
    toastBg: Colors.white.withOpacity(0.6),
    toastText: Colors.black,
    divider: Color(0xFF232B3B),
  );

  @override
  ThemeExtension<ColorThemeExtension> copyWith({
    Color? border,
    Color? border2,
    Color? border3,
    Color? highlight,
    Color? drag_indicator,
    Color? shadow,
    Color? errorBannerBg,
    Color? me,
    Color? toastBg,
    Color? toastText,
    Color? divider,
  }) {
    return ColorThemeExtension(
      border: border ?? this.border,
      border2: border2 ?? this.border2,
      border3: border3 ?? this.border3,
      highlight: highlight ?? this.highlight,
      drag_indicator: drag_indicator ?? this.drag_indicator,
      shadow: shadow ?? this.shadow,
      errorBannerBg: errorBannerBg ?? this.errorBannerBg,
      me: me ?? this.me,
      toastBg: toastBg ?? this.toastBg,
      toastText: toastText ?? this.toastText,
      divider: divider ?? this.divider,
    );
  }

  @override
  ThemeExtension<ColorThemeExtension> lerp(
      ThemeExtension<ColorThemeExtension>? other, double t) {
    if (other is! ColorThemeExtension) {
      return this;
    }
    return ColorThemeExtension(
      border: Color.lerp(border, other.border, t),
      border2: Color.lerp(border2, other.border2, t),
      border3: Color.lerp(border3, other.border3, t),
      highlight: Color.lerp(highlight, other.highlight, t),
      drag_indicator: Color.lerp(drag_indicator, other.drag_indicator, t),
      shadow: Color.lerp(shadow, other.shadow, t),
      errorBannerBg: Color.lerp(shadow, other.errorBannerBg, t),
      me: Color.lerp(shadow, other.me, t),
      toastBg: Color.lerp(shadow, other.toastBg, t),
      toastText: Color.lerp(shadow, other.toastText, t),
      divider: Color.lerp(shadow, other.divider, t),
    );
  }
}

class TabbarTheme extends ThemeExtension<TabbarTheme> {
  final Color? selectedTabIconColor;
  final Color? unSelectedTabIconColor;
  final Color? selectedTextColor;
  final Color? unSelectedTextColor;
  final Color? selectedIconColor;
  final Color? unSelectedIconColor;
  final Color? dividerColor;
  final Color? hoverColor;
  final Color? closeHoverColor;
  final Color? selectedTabBackgroundColor;

  const TabbarTheme(
      {required this.selectedTabIconColor,
      required this.unSelectedTabIconColor,
      required this.selectedTextColor,
      required this.unSelectedTextColor,
      required this.selectedIconColor,
      required this.unSelectedIconColor,
      required this.dividerColor,
      required this.hoverColor,
      required this.closeHoverColor,
      required this.selectedTabBackgroundColor});

  static const light = TabbarTheme(
      selectedTabIconColor: MyTheme.accent,
      unSelectedTabIconColor: Color.fromARGB(255, 162, 203, 241),
      selectedTextColor: Colors.black,
      unSelectedTextColor: Color.fromARGB(255, 112, 112, 112),
      selectedIconColor: Color.fromARGB(255, 26, 26, 26),
      unSelectedIconColor: Color.fromARGB(255, 96, 96, 96),
      dividerColor: Color.fromARGB(255, 238, 238, 238),
      hoverColor: Colors.white54,
      closeHoverColor: Colors.white,
      selectedTabBackgroundColor: Colors.white54);

  static const dark = TabbarTheme(
      selectedTabIconColor: MyTheme.accent,
      unSelectedTabIconColor: Color.fromARGB(255, 30, 65, 98),
      selectedTextColor: Colors.white,
      unSelectedTextColor: Color.fromARGB(255, 192, 192, 192),
      selectedIconColor: Color.fromARGB(255, 192, 192, 192),
      unSelectedIconColor: Color.fromARGB(255, 255, 255, 255),
      dividerColor: Color.fromARGB(255, 64, 64, 64),
      hoverColor: Colors.black26,
      closeHoverColor: Colors.black,
      selectedTabBackgroundColor: Colors.black26);

  @override
  ThemeExtension<TabbarTheme> copyWith({
    Color? selectedTabIconColor,
    Color? unSelectedTabIconColor,
    Color? selectedTextColor,
    Color? unSelectedTextColor,
    Color? selectedIconColor,
    Color? unSelectedIconColor,
    Color? dividerColor,
    Color? hoverColor,
    Color? closeHoverColor,
    Color? selectedTabBackgroundColor,
  }) {
    return TabbarTheme(
      selectedTabIconColor: selectedTabIconColor ?? this.selectedTabIconColor,
      unSelectedTabIconColor:
          unSelectedTabIconColor ?? this.unSelectedTabIconColor,
      selectedTextColor: selectedTextColor ?? this.selectedTextColor,
      unSelectedTextColor: unSelectedTextColor ?? this.unSelectedTextColor,
      selectedIconColor: selectedIconColor ?? this.selectedIconColor,
      unSelectedIconColor: unSelectedIconColor ?? this.unSelectedIconColor,
      dividerColor: dividerColor ?? this.dividerColor,
      hoverColor: hoverColor ?? this.hoverColor,
      closeHoverColor: closeHoverColor ?? this.closeHoverColor,
      selectedTabBackgroundColor:
          selectedTabBackgroundColor ?? this.selectedTabBackgroundColor,
    );
  }

  @override
  ThemeExtension<TabbarTheme> lerp(
      ThemeExtension<TabbarTheme>? other, double t) {
    if (other is! TabbarTheme) {
      return this;
    }
    return TabbarTheme(
      selectedTabIconColor:
          Color.lerp(selectedTabIconColor, other.selectedTabIconColor, t),
      unSelectedTabIconColor:
          Color.lerp(unSelectedTabIconColor, other.unSelectedTabIconColor, t),
      selectedTextColor:
          Color.lerp(selectedTextColor, other.selectedTextColor, t),
      unSelectedTextColor:
          Color.lerp(unSelectedTextColor, other.unSelectedTextColor, t),
      selectedIconColor:
          Color.lerp(selectedIconColor, other.selectedIconColor, t),
      unSelectedIconColor:
          Color.lerp(unSelectedIconColor, other.unSelectedIconColor, t),
      dividerColor: Color.lerp(dividerColor, other.dividerColor, t),
      hoverColor: Color.lerp(hoverColor, other.hoverColor, t),
      closeHoverColor: Color.lerp(closeHoverColor, other.closeHoverColor, t),
      selectedTabBackgroundColor: Color.lerp(
          selectedTabBackgroundColor, other.selectedTabBackgroundColor, t),
    );
  }

  static color(BuildContext context) {
    return Theme.of(context).extension<ColorThemeExtension>()!;
  }
}
