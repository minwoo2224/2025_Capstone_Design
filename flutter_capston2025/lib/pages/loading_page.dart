import 'dart:convert';
import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import 'package:lottie/lottie.dart';
import '../models/insect_card.dart';
import '../socket/socket_service.dart';
import 'card_selection_page.dart';

class LoadingPage extends StatefulWidget {
  final bool isMale;
  const LoadingPage({Key? key, required this.isMale}) : super(key: key);

  @override
  State<LoadingPage> createState() => _LoadingPageState();
}

class _LoadingPageState extends State<LoadingPage> {
  late Future<void> _initFuture;

  @override
  void initState() {
    super.initState();
    _initFuture = _initializeWithMinimumDelay();
  }

  Future<void> _initializeWithMinimumDelay() async {
    final stopwatch = Stopwatch()..start();

    final cards = await _loadUserInsects();
    bool isConnected = false;

    final completer = Completer<void>();

    SocketService.connect(
      onConnected: () {
        isConnected = true;
        completer.complete();
      },
      onCardsReceived: (_) {},
      onMatched: () {},
    );

    await Future.wait([
      completer.future,
      Future.delayed(const Duration(seconds: 3)),
    ]);

    if (!mounted) return;

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (_) => CardSelectionPage(allCards: cards),
      ),
    );
  }

  Future<List<InsectCard>> _loadUserInsects() async {
    final dir = await getApplicationDocumentsDirectory();
    final photoDir = Directory('${dir.path}/insect_photos');

    if (!await photoDir.exists()) return [];

    final files = photoDir
        .listSync()
        .whereType<File>()
        .where((file) => file.path.endsWith('.json'));

    List<InsectCard> cards = [];

    for (final file in files) {
      try {
        final content = await file.readAsString();
        final data = jsonDecode(content);
        cards.add(InsectCard.fromJson(data));
      } catch (_) {}
    }

    return cards;
  }

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    final lottiePath = widget.isMale
        ? 'assets/images/User_sex/loading_character_male.json'
        : 'assets/images/User_sex/loading_character_female.json';

    return Scaffold(
      body: Stack(
        children: [
          Positioned.fill(
            child: Image.asset(
              'assets/images/background/loading_background.png',
              fit: BoxFit.cover,
            ),
          ),
          Positioned(
            top: screenHeight * 0.4 - 10,
            left: 0,
            right: 0,
            child: Lottie.asset(
              lottiePath,
              width: 400,
              height: 400,
              fit: BoxFit.contain,
              repeat: true,
            ),
          ),
          Positioned(
            bottom: 60,
            left: 0,
            right: 0,
            child: Column(
              children: const [
                Text(
                  'TIP.',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  '최대한 많은 곤충을 찍어보세요\n곤충의 능력치는 랜덤으로 부여됩니다.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.white70, fontSize: 14),
                ),
                SizedBox(height: 16),
                Text(
                  '★ LOADING...',
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.amber,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.2,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}