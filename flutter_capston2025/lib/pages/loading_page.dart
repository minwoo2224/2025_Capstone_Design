import 'dart:convert';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import '../models/insect_card.dart';
import '../socket/socket_service.dart';
import 'card_selection_page.dart';

class LoadingPage extends StatefulWidget {
  const LoadingPage({Key? key}) : super(key: key);

  @override
  State<LoadingPage> createState() => _LoadingPageState();
}

class _LoadingPageState extends State<LoadingPage>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  late Animation<double> _translateAnimation;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      duration: const Duration(seconds: 6),
      vsync: this,
    )..repeat();

    _scaleAnimation = Tween<double>(begin: 1.0, end: 1.35).animate(
      CurvedAnimation(parent: _controller, curve: Curves.linear),
    );

    _translateAnimation = Tween<double>(begin: 0.0, end: -60.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.linear),
    );

    WidgetsBinding.instance.addPostFrameCallback((_) => _initialize());
  }

  Future<void> _initialize() async {
    try {
      final cards = await _loadAllCardsFromAssets();

      SocketService.connect(
        onConnected: () {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (_) => CardSelectionPage(allCards: cards),
            ),
          );
        },
        onCardsReceived: (_) {},
        onMatched: () {},
      );
    } catch (e) {
      print('카드 로딩 실패: $e');
      // TODO: 사용자에게 오류 알림 UI 또는 재시도 버튼 구현 고려
    }
  }

  Future<List<InsectCard>> _loadAllCardsFromAssets() async {
    final manifestContent = await rootBundle.loadString('AssetManifest.json');
    final Map<String, dynamic> manifestMap = json.decode(manifestContent);

    final cardJsonPaths = manifestMap.keys
        .where((path) => path.startsWith('assets/cards/') && path.endsWith('.json'))
        .toList();

    List<InsectCard> cards = [];

    for (String path in cardJsonPaths) {
      final jsonString = await rootBundle.loadString(path);
      final jsonMap = json.decode(jsonString);
      cards.add(InsectCard.fromJson(jsonMap));
    }

    return cards;
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;

    return Scaffold(
      body: AnimatedBuilder(
        animation: _controller,
        builder: (_, __) {
          double verticalShake = math.sin(_controller.value * 2 * math.pi) * 10;
          const int treeCount = 3;
          List<Widget> animatedTrees = [];

          for (int i = 0; i < treeCount; i++) {
            double phase = (_controller.value + i * 0.33) % 1.0;
            double treeLeft = screenWidth * 0.1 - (phase * screenWidth * 0.9);
            double treeRight = screenWidth * 0.1 - (phase * screenWidth * 0.9);
            double treeScale = 1.5 + phase * 3.5;

            animatedTrees.add(Positioned(
              top: screenHeight * 0.4,
              left: treeLeft,
              child: Transform.scale(
                scale: treeScale,
                child: Image.asset(
                  'assets/images/background/loading_tree1.png',
                  width: 120,
                  opacity: const AlwaysStoppedAnimation(1),
                ),
              ),
            ));

            animatedTrees.add(Positioned(
              top: screenHeight * 0.4,
              right: treeRight,
              child: Transform.scale(
                scale: treeScale,
                child: Image.asset(
                  'assets/images/background/loading_tree1.png',
                  width: 130,
                  opacity: const AlwaysStoppedAnimation(1),
                ),
              ),
            ));
          }

          return Stack(
            children: [
              Positioned.fill(
                child: Transform(
                  alignment: const Alignment(0.0, -0.25),
                  transform: Matrix4.identity()
                    ..translate(0.0, _translateAnimation.value + verticalShake)
                    ..scale(_scaleAnimation.value),
                  child: Image.asset(
                    'assets/images/background/loading_background.png',
                    fit: BoxFit.cover,
                  ),
                ),
              ),
              ...animatedTrees,
              const Center(
                child: Text(
                  '서버에 연결 중입니다...',
                  style: TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                    shadows: [
                      Shadow(
                        blurRadius: 8,
                        color: Colors.black,
                        offset: Offset(2, 2),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
