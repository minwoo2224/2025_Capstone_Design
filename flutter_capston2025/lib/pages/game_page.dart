import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_capston2025/models/insect_card.dart';
import 'package:flutter_capston2025/socket/socket_service.dart';

class GamePage extends StatefulWidget {
  final String userUid;
  final List<InsectCard> playerCards;
  final List<dynamic> opponentCards;
  final Color themeColor;

  const GamePage({
    Key? key,
    required this.userUid,
    required this.playerCards,
    required this.opponentCards,
    required this.themeColor,
  }) : super(key: key);

  @override
  State<GamePage> createState() => _GamePageState();
}

class _GamePageState extends State<GamePage> with TickerProviderStateMixin {
  int? selectedCardIndex;
  String battleLog = '';
  int round = 1;
  List<dynamic> opponentCards = [];

  // 애니메이션 관련 변수
  late AnimationController _attackController;
  late Animation<Offset> _playerAttackAnim;
  late Animation<Offset> _enemyHitAnim;

  int damageAmount = 0;
  bool showPlayerDamage = false;
  bool showEnemyDamage = false;

  String? playerImage;
  String? opponentImage;

  @override
  void initState() {
    super.initState();
    opponentCards = widget.opponentCards;

    _attackController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );

    _playerAttackAnim = Tween<Offset>(
      begin: Offset.zero,
      end: const Offset(0.4, -0.2),
    ).chain(CurveTween(curve: Curves.easeOut)).animate(_attackController);

    _enemyHitAnim = Tween<Offset>(
      begin: Offset.zero,
      end: const Offset(-0.1, 0.1),
    ).chain(CurveTween(curve: Curves.elasticIn)).animate(_attackController);

    SocketService.socket.on('matchResult', _onMatchResult);
    SocketService.socket.on('nextRound', _onNextRound);
    SocketService.socket.on('cardsInfo', _onCardsInfo);
    SocketService.socket.on('updateStatus', _onUpdateStatus);
    SocketService.socket.on('updateResult', _onUpdateResult);
    SocketService.socket.on('critical', _onCritical);
    SocketService.socket.on('miss', _onMiss);
  }

  @override
  void dispose() {
    _attackController.dispose();
    SocketService.socket.off('matchResult', _onMatchResult);
    SocketService.socket.off('nextRound', _onNextRound);
    SocketService.socket.off('cardsInfo', _onCardsInfo);
    SocketService.socket.off('updateStatus', _onUpdateStatus);
    SocketService.socket.off('updateResult', _onUpdateResult);
    SocketService.socket.off('critical', _onCritical);
    SocketService.socket.off('miss', _onMiss);
    super.dispose();
  }

  void _onMatchResult(dynamic msg) {
    setState(() => battleLog = msg.toString());
  }

  void _onNextRound(dynamic data) {
    setState(() {
      battleLog = '다음 라운드 시작';
      selectedCardIndex = null;
      round += 1;
    });
  }

  void _onCardsInfo(dynamic data) {
    setState(() => opponentCards = data);
  }

  void _onCritical(dynamic msg) {
    setState(() => battleLog = msg.toString());
  }

  void _onMiss(dynamic msg) {
    setState(() => battleLog = msg.toString());
  }

  void _onUpdateResult(dynamic msg) {
    setState(() => battleLog = msg.toString());
  }

  void _onUpdateStatus(dynamic data) async {
    final selfName = data['self'];
    final enemyName = data['enemy'];
    final selfHp = data['selfHp'];
    final enemyHp = data['enemyHp'];

    final isPlayerTurn = widget.playerCards[selectedCardIndex!].name == selfName;

    setState(() {
      playerImage = widget.playerCards[selectedCardIndex!].image;
      opponentImage = opponentCards.firstWhere((c) => c['name'] == enemyName)['image'];
      damageAmount = (enemyHp - selfHp).abs();
      showPlayerDamage = !isPlayerTurn;
      showEnemyDamage = isPlayerTurn;
    });

    await _attackController.forward(from: 0);

    await Future.delayed(const Duration(milliseconds: 400));

    setState(() {
      showPlayerDamage = false;
      showEnemyDamage = false;
    });
  }

  void _selectCard(int index) {
    if (selectedCardIndex != null) return;

    setState(() {
      selectedCardIndex = index;
      battleLog = '선택한 카드: ${widget.playerCards[index].name}';
    });

    SocketService.selectCard(index);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('게임 - Round $round'),
        backgroundColor: widget.themeColor,
      ),
      body: Stack(
        children: [
          if (playerImage != null && opponentImage != null) ...[
            // 상대 곤충
            Positioned(
              top: 60,
              right: 16,
              child: SlideTransition(
                position: _enemyHitAnim,
                child: Stack(
                  children: [
                    Image.asset(opponentImage!, height: 100),
                    if (showEnemyDamage)
                      Positioned(
                        left: -60,
                        child: Text('-$damageAmount', style: const TextStyle(fontSize: 20, color: Colors.red)),
                      ),
                  ],
                ),
              ),
            ),

            // 내 곤충
            Positioned(
              bottom: 120,
              left: 16,
              child: SlideTransition(
                position: _playerAttackAnim,
                child: Stack(
                  children: [
                    Image.asset(playerImage!, height: 100),
                    if (showPlayerDamage)
                      Positioned(
                        right: -60,
                        child: Text('-$damageAmount', style: const TextStyle(fontSize: 20, color: Colors.red)),
                      ),
                  ],
                ),
              ),
            ),
          ],

          // 전투 로그
          Positioned(
            bottom: 16,
            left: 16,
            right: 16,
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(battleLog, textAlign: TextAlign.center),
            ),
          ),

          // 카드 선택 UI
          if (selectedCardIndex == null) ...[
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              bottom: 180,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: widget.playerCards.length,
                itemBuilder: (context, index) {
                  final card = widget.playerCards[index];
                  return GestureDetector(
                    onTap: () => _selectCard(index),
                    child: Container(
                      margin: const EdgeInsets.all(10),
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        border: Border.all(color: Colors.blue),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Image.asset(card.image, height: 60),
                          Text(card.name),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ],
      ),
    );
  }
}
