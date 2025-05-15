import 'package:flutter/material.dart';
import '../main.dart'; // MainNavigation이 정의된 위치

class TitleScreen extends StatefulWidget {
  const TitleScreen({super.key});

  @override
  State<TitleScreen> createState() => _TitleScreenState();
}

class _TitleScreenState extends State<TitleScreen> with TickerProviderStateMixin {
  late AnimationController _beetleController;
  late AnimationController _mantisController;
  late AnimationController _titleController;
  late AnimationController _touchTextController;
  late AnimationController _fadeOutController;

  late Animation<Offset> _beetleOffset;
  late Animation<Offset> _mantisOffset;
  late Animation<double> _titleScale;
  late Animation<double> _touchOpacity;
  late Animation<double> _whiteFade;

  bool canTap = false;

  @override
  void initState() {
    super.initState();

    // 1. 장수풍뎅이 (아래 → 위)
    _beetleController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );
    _beetleOffset = Tween<Offset>(
      begin: const Offset(0, 1.2),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _beetleController, curve: Curves.easeOut));

    // 2. 사마귀 (왼쪽 → 오른쪽)
    _mantisController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );
    _mantisOffset = Tween<Offset>(
      begin: const Offset(-1.5, 1.5), // 화면 바깥 왼쪽 아래
      end: Offset.zero,               // Align 기준의 위치로 이동
    ).animate(CurvedAnimation(
      parent: _mantisController,
      curve: Curves.easeOut,
    ));

    // 3. 타이틀 (뿅)
    _titleController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _titleScale = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _titleController, curve: Curves.elasticOut),
    );

    // 4. "터치해서 시작" 깜빡이기
    _touchTextController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 1),
    );
    _touchOpacity = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _touchTextController, curve: Curves.easeInOut),
    );

    // 5. 흰색 페이드 아웃
    _fadeOutController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );
    _whiteFade = Tween<double>(begin: 0.0, end: 1.0).animate(_fadeOutController);

    // 애니메이션 순차 실행
    _startAnimations();
  }

  void _startAnimations() async {
    await _beetleController.forward();
    await _mantisController.forward();
    await _titleController.forward();

    _touchTextController.repeat(reverse: true);
    setState(() => canTap = true);
  }

  @override
  void dispose() {
    _beetleController.dispose();
    _mantisController.dispose();
    _titleController.dispose();
    _touchTextController.dispose();
    _fadeOutController.dispose();
    super.dispose();
  }

  void _handleTap() {
    if (!canTap) return;

    _fadeOutController.forward().then((_) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const MainNavigation()),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: _handleTap,
      child: Stack(
        fit: StackFit.expand,
        children: [
          // 배경색
          Container(color: Colors.white),

          // 사마귀 (왼쪽에서 들어옴)
          SlideTransition(
            position: _mantisOffset,
            child: Align(
              alignment: Alignment.bottomLeft, // 끝 위치를 bottomLeft로 고정
              child: Image.asset(
                'assets/title/mantis.png',
                width: 240,
              ),
            ),
          ),

          // 장수풍뎅이 (아래에서 올라옴)
          SlideTransition(
            position: _beetleOffset,
            child: Align(
              alignment: Alignment.bottomRight,
              child: Image.asset(
                'assets/title/rhinoceros_beetle.png',
                width: 350,
              ),
            ),
          ),

          // 타이틀 텍스트
          Center(
            child: ScaleTransition(
              scale: _titleScale,
              child: const Text(
                '곤충 탐험대',
                style: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                  decoration: TextDecoration.none,
                ),
              ),
            ),
          ),

          // "터치해서 시작"
          Align(
            alignment: Alignment.bottomCenter,
            child: Padding(
              padding: const EdgeInsets.only(bottom: 50),
              child: FadeTransition(
                opacity: _touchOpacity,
                child: const Text(
                  '터치해서 시작',
                  style: TextStyle(
                    fontSize: 18,
                    color: Colors.black54,
                    decoration: TextDecoration.none,
                  ),
                ),
              ),
            ),
          ),

          // 하얀색 전환 오버레이
          AnimatedBuilder(
            animation: _whiteFade,
            builder: (context, child) => Opacity(
              opacity: _whiteFade.value,
              child: Container(color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }
}