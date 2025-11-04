import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/services.dart';

enum AppTheme { dark, paper, white }

class ThemeController extends ChangeNotifier {
  static const _k = 'appTheme';
  AppTheme _theme = AppTheme.dark;

  AppTheme get theme => _theme;
  bool get isDark => _theme == AppTheme.dark;
  bool get isPaper => _theme == AppTheme.paper;
  bool get isWhite => _theme == AppTheme.white;

  Future<void> load() async {
    final p = await SharedPreferences.getInstance();
    final idx = p.getInt(_k);
    if (idx != null && idx >= 0 && idx < AppTheme.values.length) {
      _theme = AppTheme.values[idx];
      notifyListeners();
    }
  }

  Future<void> setTheme(AppTheme t) async {
    _theme = t;
    notifyListeners();
    final p = await SharedPreferences.getInstance();
    await p.setInt(_k, t.index);
  }

  ThemeData get materialTheme {
    switch (_theme) {
      //검정 테마
      case AppTheme.dark: {
        final base = ThemeData.dark();
        return base.copyWith(
          scaffoldBackgroundColor: const Color(0xFF121212),
          textTheme: base.textTheme.apply(
              bodyColor: Colors.white, displayColor: Colors.white),
          appBarTheme: const AppBarTheme(
            systemOverlayStyle: SystemUiOverlayStyle(
              statusBarColor: Color(0xFF121212),
              statusBarIconBrightness: Brightness.light,
              statusBarBrightness: Brightness.dark,
            ),
            centerTitle: true,
            elevation: 0,
          ),
        );
      }
      //종이 테마
      case AppTheme.paper: {
        final base = ThemeData.light();
        // AppBar는 페이지에서 배경이미지를 그릴 수도 있으니 단색으로만 지정
        const barColor = Color(0xFFe5e5e5);
        return base.copyWith(
          scaffoldBackgroundColor: Colors.white,
          appBarTheme: const AppBarTheme(
            backgroundColor: barColor,
            foregroundColor: Colors.black87,
            centerTitle: true,
            elevation: 0,
            systemOverlayStyle: SystemUiOverlayStyle(
              statusBarColor: barColor,
              statusBarIconBrightness: Brightness.dark,
              statusBarBrightness: Brightness.light,
            ),
          ),
          bottomAppBarTheme: const BottomAppBarTheme(
            color: Colors.white,
            elevation: 6,
          ),
          textTheme: base.textTheme.apply(
              bodyColor: Colors.black87, displayColor: Colors.black87),
          colorScheme: base.colorScheme.copyWith(primary: Colors.deepPurple),
        );
      }
      //하양 테마
      case AppTheme.white: {
        final base = ThemeData.light();
        const appBarLightGrey = Color(0xFFF2F2F6);
        return base.copyWith(
          scaffoldBackgroundColor: Colors.white,
          appBarTheme: const AppBarTheme(
            backgroundColor: appBarLightGrey,
            foregroundColor: Colors.black87,
            surfaceTintColor: Colors.transparent,
            centerTitle: true,
            elevation: 0.5,
            systemOverlayStyle: SystemUiOverlayStyle(
              statusBarColor: appBarLightGrey,
              statusBarIconBrightness: Brightness.dark,
              statusBarBrightness: Brightness.light,
            ),
          ),
          bottomAppBarTheme: const BottomAppBarTheme(
            color: Colors.white,
            elevation: 6,
          ),
          textTheme: base.textTheme.apply(
              bodyColor: Colors.black87, displayColor: Colors.black87),
          colorScheme: base.colorScheme.copyWith(primary: Colors.deepPurple),
        );
      }
    }
  }
}
