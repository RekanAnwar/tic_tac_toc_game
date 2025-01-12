import 'package:flutter/material.dart';

extension ContextExt on BuildContext {
  ThemeData get theme => Theme.of(this);

  ColorScheme get colorScheme => theme.colorScheme;

  Locale get locale => Localizations.localeOf(this);

  String get languageCode => locale.languageCode;

  Color get primary => colorScheme.primary;

  Color get primaryContainer => colorScheme.primaryContainer;

  Color get secondary => colorScheme.secondary;

  Color get secondaryContainer => colorScheme.secondaryContainer;

  Color get tertiary => colorScheme.tertiary;

  Color get tertiaryContainer => colorScheme.tertiaryContainer;

  Color get buttonColor => isDark ? colorScheme.surface : colorScheme.secondary;

  Color get scaffoldBackground => theme.scaffoldBackgroundColor;

  Color get surface => colorScheme.surface;

  Color get inverseSurface => colorScheme.inverseSurface;

  Color get textColor => bodyMedium.color!;

  Size get mSize => MediaQuery.sizeOf(this);

  bool get isDark => theme.brightness == Brightness.dark;

  TextTheme get textTheme => theme.textTheme;

  TextStyle get bodyMedium => textTheme.bodyMedium!;

  TextStyle get bodyLarge => textTheme.bodyLarge!;

  TextStyle get bodySmall => textTheme.bodySmall!;

  TextStyle get titleMedium => textTheme.titleMedium!;

  TextStyle get titleLarge => textTheme.titleLarge!;

  TextStyle get titleSmall => textTheme.titleSmall!;

  TextStyle get headlineMedium => textTheme.headlineMedium!;

  TextStyle get headlineSmall => textTheme.headlineSmall!;

  TextStyle get headlineLarge => textTheme.headlineLarge!;

  TextStyle get labelMedium => textTheme.labelMedium!;

  TextStyle get labelSmall => textTheme.labelSmall!;

  TextStyle get labelLarge => textTheme.labelLarge!;

  double get width => mSize.width;

  double get height => mSize.height;

  Color get grey50 => colorScheme.inverseSurface.setOpacity(0.05);

  Color get grey100 => colorScheme.inverseSurface.setOpacity(0.1);

  Color get grey200 => colorScheme.inverseSurface.setOpacity(0.2);

  Color get grey300 => colorScheme.inverseSurface.setOpacity(0.3);

  Color get grey400 => colorScheme.inverseSurface.setOpacity(0.4);

  Color get grey500 => colorScheme.inverseSurface.setOpacity(0.5);

  Color get grey600 => colorScheme.inverseSurface.setOpacity(0.6);

  Color get grey700 => colorScheme.inverseSurface.setOpacity(0.7);

  Color get grey800 => colorScheme.inverseSurface.setOpacity(0.8);

  Color get grey900 => colorScheme.inverseSurface.setOpacity(0.9);

  Color get primary100 => colorScheme.primary.setOpacity(0.1);

  Color get primary200 => colorScheme.primary.setOpacity(0.2);

  Color get primary300 => colorScheme.primary.setOpacity(0.3);

  Color get primary400 => colorScheme.primary.setOpacity(0.4);

  Color get primary500 => colorScheme.primary.setOpacity(0.5);

  Color get primary600 => colorScheme.primary.setOpacity(0.6);

  Color get primary700 => colorScheme.primary.setOpacity(0.7);

  Color get primary800 => colorScheme.primary.setOpacity(0.8);

  Color get primary900 => colorScheme.primary.setOpacity(0.9);

  Color get secondary100 => colorScheme.secondary.setOpacity(0.1);

  Color get secondary200 => colorScheme.secondary.setOpacity(0.2);

  Color get secondary300 => colorScheme.secondary.setOpacity(0.3);

  Color get secondary400 => colorScheme.secondary.setOpacity(0.4);

  Color get secondary500 => colorScheme.secondary.setOpacity(0.5);

  Color get secondary600 => colorScheme.secondary.setOpacity(0.6);

  Color get secondary700 => colorScheme.secondary.setOpacity(0.7);

  Color get secondary800 => colorScheme.secondary.setOpacity(0.8);

  Color get secondary900 => colorScheme.secondary.setOpacity(0.9);
}

extension ColorExtension on Color {
  Color setOpacity(double opacity) => this.withValues(alpha: opacity);
}
