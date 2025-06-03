import 'package:flutter/material.dart';
import '../main.dart'; // MainNavigation이 정의된 위치
import '../pages/login_page.dart';
import '../storage/login_storage.dart';

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

    _beetleController = AnimationController(vsync: this, duration: const Duration(milliseconds: 1200));
    _beetleOffset = Tween<Offset>(begin: const Offset(0, 1.2), end: Offset.zero)
        .animate(CurvedAnimation(parent: _beetleController, curve: Curves.easeOut));

    _mantisController = AnimationController(vsync: this, duration: const Duration(milliseconds: 1000));
    _mantisOffset = Tween<Offset>(begin: const Offset(-1.5, 1.5), end: Offset.zero)
        .animate(CurvedAnimation(parent: _mantisController, curve: Curves.easeOut));

    _titleController = AnimationController(vsync: this, duration: const Duration(milliseconds: 600));
    _titleScale = Tween<double>(begin: 0.0, end: 1.0)
        .animate(CurvedAnimation(parent: _titleController, curve: Curves.elasticOut));

    _touchTextController = AnimationController(vsync: this, duration: const Duration(seconds: 1));
    _touchOpacity = Tween<double>(begin: 0.0, end: 1.0)
        .animate(CurvedAnimation(parent: _touchTextController, curve: Curves.easeInOut));

    _fadeOutController = AnimationController(vsync: this, duration: const Duration(milliseconds: 1000));
    _whiteFade = Tween<double>(begin: 0.0, end: 1.0).animate(_fadeOutController);

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

  void _handleTap() async {
    if (!canTap) return;

    _fadeOutController.forward().then((_) async {
      final guestInfo = await readLoginInfo(guest: true);
      final userInfo = await readLoginInfo(guest: false);
      final isGuest = guestInfo.isNotEmpty;
      final isLoggedIn = userInfo.isNotEmpty;

      if (!mounted) return;

      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (_) => isGuest
              ? MainNavigation(isGuest: true, selectedIndex: 4, loginInfo: guestInfo)
              : isLoggedIn
              ? MainNavigation(isGuest: false, selectedIndex: 4, loginInfo: userInfo)
              : const LoginPage(),
        ),
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
          Container(color: Colors.white),

          SlideTransition(
            position: _mantisOffset,
            child: Align(
              alignment: Alignment.bottomLeft,
              child: Image.asset('assets/images/title/mantis.png', width: 300),
            ),
          ),

          SlideTransition(
            position: _beetleOffset,
            child: Align(
              alignment: Alignment.bottomRight,
              child: Image.asset('assets/images/title/rhinoceros_beetle.png', width: 350),
            ),
          ),

          Positioned(
            top: MediaQuery.of(context).size.height * 0.18,
            left: 0,
            right: 0,
            child: ScaleTransition(
              scale: _titleScale,
              child: Image.asset(
                'assets/images/title/title.png',
                width: 315,
              ),
            ),
          ),

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
                    fontWeight: FontWeight.bold,
                    color: Colors.black,
                    decoration: TextDecoration.none,
                    shadows: [
                      Shadow(offset: Offset(-2, -2), color: Colors.white),
                      Shadow(offset: Offset(2, -2), color: Colors.white),
                      Shadow(offset: Offset(-2, 2), color: Colors.white),
                      Shadow(offset: Offset(2, 2), color: Colors.white),
                    ],
                  ),
                ),
              ),
            ),
          ),

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