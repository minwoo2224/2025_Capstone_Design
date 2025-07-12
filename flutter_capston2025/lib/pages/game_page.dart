import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_capston2025/models/insect_card.dart';
import 'package:flutter_capston2025/pages/battle_card_selection_page.dart';
import 'package:flutter_capston2025/socket/socket_service.dart';

class GamePage extends StatefulWidget {
  final String userUid;
  final List<InsectCard> playerCards;
  final List<InsectCard> opponentCards;
  final Color themeColor;
  final int round;

  const GamePage({
    Key? key,
    required this.userUid,
    required this.playerCards,
    required this.opponentCards,
    required this.themeColor,
    this.round = 1,
  }) : super(key: key);

  @override
  State<GamePage> createState() => _GamePageState();
}

class _GamePageState extends State<GamePage> with TickerProviderStateMixin {
  late InsectCard playerCard;
  late InsectCard opponentCard;

  late AnimationController _attackController;
  late Animation<Offset> _playerAttackAnim;
  late Animation<Offset> _enemyHitAnim;

  int playerHp = 0;
  int opponentHp = 0;
  String battleLog = '';
  int damageAmount = 0;

  bool showPlayerDamage = false;
  bool showEnemyDamage = false;

  @override
  void initState() {
    super.initState();
    playerCard = widget.playerCards.first;
    opponentCard = widget.opponentCards.first;

    playerHp = playerCard.health;
    opponentHp = opponentCard.health;

    _attackController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );

    _playerAttackAnim = Tween<Offset>(
      begin: Offset.zero,
      end: const Offset(0.2, -0.1),
    ).chain(CurveTween(curve: Curves.easeOut)).animate(_attackController);

    _enemyHitAnim = Tween<Offset>(
      begin: Offset.zero,
      end: const Offset(-0.1, 0.1),
    ).chain(CurveTween(curve: Curves.elasticIn)).animate(_attackController);

    SocketService.socket.on('updateStatus', _onUpdateStatus);
    SocketService.socket.on('updateResult', _onUpdateResult);
    SocketService.socket.on('critical', _onCritical);
    SocketService.socket.on('miss', _onMiss);
    SocketService.socket.on('normalAttack', _onNormalAttack);

    SocketService.setNextRoundCallback(_onNextRound);
  }

  @override
  void dispose() {
    _attackController.dispose();
    SocketService.socket.off('updateStatus', _onUpdateStatus);
    SocketService.socket.off('updateResult', _onUpdateResult);
    SocketService.socket.off('critical', _onCritical);
    SocketService.socket.off('miss', _onMiss);
    SocketService.socket.off('normalAttack', _onNormalAttack);
    super.dispose();
  }

  void _onUpdateStatus(dynamic data) async {
    final selfName = data['self'];
    final selfHp = data['selfHp'];
    final enemyHp = data['enemyHp'];
    final isPlayerTurn = playerCard.name == selfName;

    setState(() {
      playerHp = isPlayerTurn ? selfHp : enemyHp;
      opponentHp = isPlayerTurn ? enemyHp : selfHp;
      showPlayerDamage = !isPlayerTurn;
      showEnemyDamage = isPlayerTurn;
    });

    await _attackController.forward(from: 0);
    await Future.delayed(const Duration(milliseconds: 500));

    if (mounted) {
      setState(() {
        showPlayerDamage = false;
        showEnemyDamage = false;
      });
    }
  }

  void _onUpdateResult(dynamic msg) {
    final result = msg.toString();
    setState(() {
      battleLog = result;
    });
  }

  void _onCritical(dynamic msg) {
    setState(() {
      battleLog = "Critical! ${playerCard.name}이 ${opponentCard.name}에게 $damageAmount 데미지를 입혔습니다";
    });
  }

  void _onMiss(dynamic msg) {
    setState(() {
      battleLog = "Miss! 공격이 빗나갔습니다.";
    });
  }

  void _onNormalAttack(dynamic data) {
    final attacker = data['attacker'];
    final defender = data['defender'];
    final damage = data['damage'];

    setState(() {
      battleLog = "$attacker이 $defender에게 $damage 데미지를 입혔습니다";
      damageAmount = damage;
    });
  }

  void _onNextRound(List<InsectCard> newMyCards, List<InsectCard> newOpponentCards) {
    final usedIndex = widget.round - 1;
    final remainingPlayerCards = List<InsectCard>.from(newMyCards);
    if (usedIndex < remainingPlayerCards.length) {
      remainingPlayerCards.removeAt(usedIndex);
    }

    Future.delayed(const Duration(seconds: 2), () {
      if (!mounted) return;
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => BattleCardSelectionPage(
            userUid: widget.userUid,
            playerCards: remainingPlayerCards,
            opponentCards: newOpponentCards,
            round: widget.round + 1,
            themeColor: widget.themeColor,
          ),
        ),
      );
    });
  }

  Widget _buildHpBar(int current, int max) {
    final percent = current / max;
    return Stack(
      children: [
        Container(
          width: 100,
          height: 8,
          decoration: BoxDecoration(
            color: Colors.red.shade200,
            borderRadius: BorderRadius.circular(4),
          ),
        ),
        Container(
          width: 100 * percent,
          height: 8,
          decoration: BoxDecoration(
            color: Colors.green,
            borderRadius: BorderRadius.circular(4),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Stack(
          children: [
            Positioned.fill(
              child: Image.asset(
                'assets/images/background/forest_background.png',
                fit: BoxFit.cover,
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Align(
                    alignment: Alignment.topRight,
                    child: SlideTransition(
                      position: _enemyHitAnim,
                      child: Column(
                        children: [
                          Image.file(File(opponentCard.image), height: 120), // ✅ 수정됨
                          _buildHpBar(opponentHp, opponentCard.health),
                          if (showEnemyDamage)
                            Text('-$damageAmount',
                                style: const TextStyle(
                                    color: Colors.red, fontSize: 20)),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 80),
                  Align(
                    alignment: Alignment.bottomLeft,
                    child: SlideTransition(
                      position: _playerAttackAnim,
                      child: Column(
                        children: [
                          Image.file(File(playerCard.image), height: 120), // ✅ 수정됨
                          _buildHpBar(playerHp, playerCard.health),
                          if (showPlayerDamage)
                            Text('-$damageAmount',
                                style: const TextStyle(
                                    color: Colors.red, fontSize: 20)),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 40),
                  Container(
                    margin: const EdgeInsets.symmetric(horizontal: 20),
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      battleLog,
                      textAlign: TextAlign.center,
                      style: const TextStyle(color: Colors.black),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}