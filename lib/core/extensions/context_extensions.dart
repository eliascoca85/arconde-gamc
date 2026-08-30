import 'package:flutter/material.dart';
import '../../app/theme/index.dart';

extension ContextExtensions on BuildContext {
  ThemeData get theme => Theme.of(this);
  ColorScheme get colorScheme => theme.colorScheme;
  TextTheme get textTheme => theme.textTheme;

  MediaQueryData get mediaQuery => MediaQuery.of(this);
  Size get screenSize => mediaQuery.size;
  double get screenWidth => screenSize.width;
  double get screenHeight => screenSize.height;
  double get statusBarHeight => mediaQuery.padding.top;
  double get bottomPadding => mediaQuery.padding.bottom;
  double get topPadding => mediaQuery.padding.top;
  double get viewPaddingBottom => mediaQuery.viewPadding.bottom;
  double get viewPaddingTop => mediaQuery.viewPadding.top;

  bool get isLandscape => mediaQuery.orientation == Orientation.landscape;
  bool get isPortrait => mediaQuery.orientation == Orientation.portrait;
  bool get isDarkMode => theme.brightness == Brightness.dark;
  bool get isTablet => screenWidth >= 600;
  bool get isDesktop => screenWidth >= 840;

  double get responsiveWidth => isTablet ? screenWidth * 0.85 : screenWidth;
  double get responsiveHeight => isTablet ? screenHeight * 0.85 : screenHeight;

  NavigatorState get navigator => Navigator.of(this);
  ScaffoldMessengerState get scaffoldMessenger => ScaffoldMessenger.of(this);
  FocusScopeNode get focusScope => FocusScope.of(this);

  void hideKeyboard() => focusScope.unfocus();

  void showSnackBar(String message, {Duration? duration, SnackBarAction? action}) {
    scaffoldMessenger.showSnackBar(
      SnackBar(
        content: Text(message),
        duration: duration ?? const Duration(seconds: 3),
        action: action,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void showErrorSnackBar(String message) {
    showSnackBar(message, duration: const Duration(seconds: 4));
  }

  void showSuccessSnackBar(String message) {
    showSnackBar(message, duration: const Duration(seconds: 3));
  }

  Future<T?> pushNamed<T extends Object?>(String routeName, {Object? arguments}) {
    return navigator.pushNamed<T>(routeName, arguments: arguments);
  }

  Future<T?> pushReplacementNamed<T extends Object?, TO extends Object?>(
    String routeName, {
    TO? result,
    Object? arguments,
  }) {
    return navigator.pushReplacementNamed<T, TO>(routeName, result: result, arguments: arguments);
  }

  void pop<T extends Object?>([T? result]) => navigator.pop(result);

  bool get canPop => navigator.canPop();
}