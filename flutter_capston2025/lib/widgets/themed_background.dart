import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../main.dart' show themeController;

class ThemedBackground extends StatelessWidget {
  final Widget child;
  const ThemedBackground({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    if (themeController.isPaper) {
      return Stack(
        children: [
          Positioned.fill(
            child: const DecoratedBox(
              decoration: BoxDecoration(
                image: DecorationImage(
                  image: AssetImage('assets/images/background/paper_texture.png'),
                  fit: BoxFit.cover,
                  alignment: Alignment.center,
                ),
              ),
            ),
          ),
          child,
        ],
      );
    }
    // dark/white는 기본 배경색 사용
    return child;
  }
}
