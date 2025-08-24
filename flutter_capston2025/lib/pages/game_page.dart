import 'dart:io';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_capston2025/models/insect_card.dart';
import 'package:flutter_capston2025/socket/socket_service.dart';

class GamePage extends StatefulWidget {
  final String userUid;
  final List<InsectCard> playerCards;   // 내가 선택한 3장
  final List<InsectCard> opponentCards; // 상대의 3장
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
  // 단계: 카드 선택(true) vs 전투(false)
  bool _inSelection = true;

  // 이번 라운드에서 내가 고르는 사람(패자)인지
  bool _iPickThisRound = true;

  // 남은 카드들
  late List<InsectCard> _myRemaining;
  late List<InsectCard> _oppRemaining;

  // 선택 상태
  int? _mySelectedIndex;
  InsectCard? _mySelectedCard;   // 내(고정/선택) 카드
  InsectCard? _oppSelectedCard;  // 상대(고정) 카드 — 선택 단계에서 엔트리 하이라이트용

  // ===== 애니메이션 컨트롤러/애니메이션 =====
  // 공격 모션 (한쪽만 전진)
  late final AnimationController _playerAttackCtrl;
  late final Animation<Offset> _playerAttackSlide;
  late final AnimationController _enemyAttackCtrl;
  late final Animation<Offset> _enemyAttackSlide;

  // 피격 깜빡임 (opacity)
  late final AnimationController _playerBlinkCtrl;
  late final Animation<double> _playerBlinkOpacity;
  late final AnimationController _enemyBlinkCtrl;
  late final Animation<double> _enemyBlinkOpacity;

  // 패배(아래로 사라짐: slide+fade)
  late final AnimationController _playerDefeatCtrl;
  late final Animation<Offset> _playerDefeatSlide;
  late final Animation<double> _playerDefeatFade;
  late final AnimationController _enemyDefeatCtrl;
  late final Animation<Offset> _enemyDefeatSlide;
  late final Animation<double> _enemyDefeatFade;

  // 데미지 팝업(위로 떠오르며 사라짐) — 1초
  late final AnimationController _playerDamageCtrl;
  late final Animation<Offset> _playerDamageSlide;
  late final Animation<double> _playerDamageFade;
  late final AnimationController _enemyDamageCtrl;
  late final Animation<Offset> _enemyDamageSlide;
  late final Animation<double> _enemyDamageFade;

  // ====== 매치 결과 오버레이(승리/패배) ======
  late final AnimationController _victoryCtrl;
  late final Animation<double> _victoryScale;
  late final Animation<double> _victoryFade;

  late final AnimationController _defeatCtrl;
  late final Animation<Offset> _defeatSlide;
  late final Animation<double> _defeatFade;

  bool _showResultOverlay = false;
  bool _isVictory = false;

  // 전투 상태
  int _playerHp = 0;
  int _opponentHp = 0;
  String _battleLog = '';

  bool _showPlayerDamage = false;
  bool _showEnemyDamage = false;
  String _playerDamageText = '';
  String _enemyDamageText = '';

  int _roundNum = 1;

  // ===== 이벤트/애니메이션 큐잉 =====
  bool _isAnimating = false;                          // 현재 애니메이션 실행 중인지
  final List<Map<String, dynamic>> _statusQueue = []; // updateStatus 이벤트 큐
  dynamic _pendingNextRoundData;                      // nextRound 보류 페이로드
  String? _pendingMatchResult;                        // matchResult 보류 메시지
  String? _pendingRoundResult;                        // updateResult 보류 메시지(라운드 승리 문구)

  // 턴 동기화를 위한 보조 상태
  bool _expectedAttackerIsMine = true; // 현재 턴의 공격자(예상). 첫 턴은 속도로 결정, 이후 매 턴 토글.
  String? _pendingTurnMsg;             // normal/critical/miss 문구(공격 애니 "동시에" 출력)

  @override
  void initState() {
    super.initState();

    _myRemaining  = List<InsectCard>.from(widget.playerCards);
    _oppRemaining = List<InsectCard>.from(widget.opponentCards);
    _roundNum = widget.round;

    // 공격 모션 (앞으로 살짝 전진)
    _playerAttackCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 240));
    _playerAttackSlide = Tween<Offset>(begin: Offset.zero, end: const Offset(0.16, -0.08))
        .chain(CurveTween(curve: Curves.easeOut))
        .animate(_playerAttackCtrl);

    _enemyAttackCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 240));
    _enemyAttackSlide = Tween<Offset>(begin: Offset.zero, end: const Offset(-0.16, 0.08))
        .chain(CurveTween(curve: Curves.easeOut))
        .animate(_enemyAttackCtrl);

    // 깜빡임(피격 표시): 1.0 -> 0.35
    _playerBlinkCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 120));
    _playerBlinkOpacity = Tween<double>(begin: 1.0, end: 0.35).animate(
      CurvedAnimation(parent: _playerBlinkCtrl, curve: Curves.easeInOut),
    );
    _enemyBlinkCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 120));
    _enemyBlinkOpacity = Tween<double>(begin: 1.0, end: 0.35).animate(
      CurvedAnimation(parent: _enemyBlinkCtrl, curve: Curves.easeInOut),
    );

    // 패배(아래로 사라짐): slide + fade
    _playerDefeatCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 360));
    _playerDefeatSlide = Tween<Offset>(begin: Offset.zero, end: const Offset(0, 0.7))
        .chain(CurveTween(curve: Curves.easeIn))
        .animate(_playerDefeatCtrl);
    _playerDefeatFade = Tween<double>(begin: 1.0, end: 0.0)
        .chain(CurveTween(curve: Curves.easeIn))
        .animate(_playerDefeatCtrl);

    _enemyDefeatCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 360));
    _enemyDefeatSlide = Tween<Offset>(begin: Offset.zero, end: const Offset(0, 0.7))
        .chain(CurveTween(curve: Curves.easeIn))
        .animate(_enemyDefeatCtrl);
    _enemyDefeatFade = Tween<double>(begin: 1.0, end: 0.0)
        .chain(CurveTween(curve: Curves.easeIn))
        .animate(_enemyDefeatCtrl);

    // 데미지 팝업(위로 떠오르며 사라짐) — 1초로 느리게
    _playerDamageCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 1000));
    _playerDamageSlide = Tween<Offset>(begin: Offset.zero, end: const Offset(0, -0.7))
        .chain(CurveTween(curve: Curves.easeOut))
        .animate(_playerDamageCtrl);
    _playerDamageFade = Tween<double>(begin: 1.0, end: 0.0)
        .chain(CurveTween(curve: Curves.easeOut))
        .animate(_playerDamageCtrl);

    _enemyDamageCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 1000));
    _enemyDamageSlide = Tween<Offset>(begin: Offset.zero, end: const Offset(0, -0.7))
        .chain(CurveTween(curve: Curves.easeOut))
        .animate(_enemyDamageCtrl);
    _enemyDamageFade = Tween<double>(begin: 1.0, end: 0.0)
        .chain(CurveTween(curve: Curves.easeOut))
        .animate(_enemyDamageCtrl);

    // ===== 결과 오버레이 컨트롤러 =====
    _victoryCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 800));
    _victoryScale = Tween<double>(begin: 0.6, end: 1.05)
        .chain(CurveTween(curve: Curves.elasticOut))
        .animate(_victoryCtrl);
    _victoryFade = CurvedAnimation(parent: _victoryCtrl, curve: Curves.easeOut);

    _defeatCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 700));
    _defeatSlide = Tween<Offset>(begin: const Offset(0, 0.15), end: Offset.zero)
        .chain(CurveTween(curve: Curves.easeOutCubic))
        .animate(_defeatCtrl);
    _defeatFade = CurvedAnimation(parent: _defeatCtrl, curve: Curves.easeOut);

    // 소켓 이벤트
    SocketService.socket
      ..off('startBattle')
      ..on('startBattle', _onStartBattle)
      ..off('updateStatus')
      ..on('updateStatus', _onUpdateStatus)
      ..off('updateResult')
      ..on('updateResult', _onUpdateResult)
      ..off('critical')
      ..on('critical', _onCritical)
      ..off('miss')
      ..on('miss', _onMiss)
      ..off('normalAttack')
      ..on('normalAttack', _onNormalAttack)
      ..off('nextRound')
      ..on('nextRound', _onNextRound)
      ..off('matchResult')
      ..on('matchResult', _onMatchResult);
  }

  @override
  void dispose() {
    _playerAttackCtrl.dispose();
    _enemyAttackCtrl.dispose();
    _playerBlinkCtrl.dispose();
    _enemyBlinkCtrl.dispose();
    _playerDefeatCtrl.dispose();
    _enemyDefeatCtrl.dispose();
    _playerDamageCtrl.dispose();
    _enemyDamageCtrl.dispose();

    _victoryCtrl.dispose();
    _defeatCtrl.dispose();

    SocketService.socket
      ..off('startBattle', _onStartBattle)
      ..off('updateStatus', _onUpdateStatus)
      ..off('updateResult', _onUpdateResult)
      ..off('critical', _onCritical)
      ..off('miss', _onMiss)
      ..off('normalAttack', _onNormalAttack)
      ..off('nextRound', _onNextRound)
      ..off('matchResult', _onMatchResult);
    super.dispose();
  }

  // ===== 유틸 =====
  Future<void> _blink(AnimationController ctrl, {int cycles = 2}) async {
    ctrl.repeat(reverse: true);
    await Future.delayed(ctrl.duration! * (cycles * 2));
    ctrl.stop();
    ctrl.reset();
  }

  Future<void> _playAttack(AnimationController ctrl) async {
    await ctrl.forward();
    await ctrl.reverse();
  }

  Future<void> _playDefeat(AnimationController ctrl) async {
    if (ctrl.isAnimating || ctrl.isCompleted) return;
    await ctrl.forward();
  }

  // ====== 상대 선택 카드 수신 → 전투 단계 진입 ======
  void _onStartBattle(dynamic data) {
    if (!mounted) return;

    final oppJson = Map<String, dynamic>.from(data);
    _oppSelectedCard = InsectCard.fromJson(oppJson);

    if (_mySelectedIndex != null &&
        _mySelectedIndex! >= 0 &&
        _mySelectedIndex! < _myRemaining.length) {
      _mySelectedCard = _myRemaining[_mySelectedIndex!];
    }

    if (_mySelectedCard == null || _oppSelectedCard == null) return;

    // 첫 턴 공격자 예측(속도 비교: 서버 로직과 동일)
    _expectedAttackerIsMine = (_mySelectedCard!.speed >= _oppSelectedCard!.speed);

    // 라운드 시작: 애니메이션 초기화
    _playerAttackCtrl.reset();
    _enemyAttackCtrl.reset();
    _playerBlinkCtrl.reset();
    _enemyBlinkCtrl.reset();
    _playerDefeatCtrl.reset();
    _enemyDefeatCtrl.reset();
    _playerDamageCtrl.reset();
    _enemyDamageCtrl.reset();

    setState(() {
      _inSelection = false;
      _playerHp   = _mySelectedCard!.health;
      _opponentHp = _oppSelectedCard!.health;
      _battleLog  = 'Round $_roundNum Start!';
      _pendingTurnMsg = null;
      _pendingRoundResult = null;
      _showPlayerDamage = false;
      _showEnemyDamage = false;
      _playerDamageText = '';
      _enemyDamageText  = '';
    });
  }

  // 턴 메시지는 보관해두었다가 "공격 애니메이션 시작과 동시에" 찍는다
  void _onNormalAttack(dynamic data) {
    final map = Map<String, dynamic>.from(data as Map);
    final attacker = map['attacker']?.toString() ?? '';
    final defender = map['defender']?.toString() ?? '';
    final dmg = (map['damage'] as num?)?.toInt() ?? 0;
    _pendingTurnMsg = '$attacker이(가) $defender에게 $dmg 데미지!';
  }

  void _onCritical(dynamic _) {
    _pendingTurnMsg = 'Critical!';
  }

  void _onMiss(dynamic _) {
    _pendingTurnMsg = 'Miss! 공격이 빗나갔습니다.';
  }

  // 라운드 승리 문구는 보류(애니 종료 후에 출력)
  void _onUpdateResult(dynamic msg) {
    _pendingRoundResult = msg.toString();
  }

  // ====== updateStatus: 큐에 넣고 순차 애니메이션 ======
  void _onUpdateStatus(dynamic data) {
    _statusQueue.add(Map<String, dynamic>.from(data as Map));
    if (!_isAnimating) {
      _drainStatusQueue();
    }
  }

  Future<void> _drainStatusQueue() async {
    _isAnimating = true;
    while (_statusQueue.isNotEmpty) {
      final map = _statusQueue.removeAt(0);

      final selfName = map['self']?.toString();
      final selfHp  = (map['selfHp'] as num?)?.toInt() ?? 0;
      final enemyHp = (map['enemyHp'] as num?)?.toInt() ?? 0;

      final isMyContext = (_mySelectedCard?.name == selfName);

      // 새로운 HP
      final newPlayerHp   = isMyContext ? selfHp  : enemyHp;
      final newOpponentHp = isMyContext ? enemyHp : selfHp;

      // 이전 HP와 비교하여 피격자 판별
      final prevPlayerHp   = _playerHp;
      final prevOpponentHp = _opponentHp;
      final playerTookDamage = newPlayerHp < prevPlayerHp;
      final enemyTookDamage  = newOpponentHp < prevOpponentHp;

      // HP 먼저 반영
      if (mounted) {
        setState(() {
          _playerHp   = newPlayerHp;
          _opponentHp = newOpponentHp;
          _showPlayerDamage = false;
          _showEnemyDamage  = false;
          _playerDamageText = '';
          _enemyDamageText  = '';
        });
      }

      // 1) 공격자만 공격 모션 (메시지는 "공격 애니메이션 시작과 동시에" 표시)
      if (enemyTookDamage) {
        // 내가 공격자
        final dealt = prevOpponentHp - newOpponentHp;
        final attackerName = _mySelectedCard?.name ?? '나';
        final defenderName = _oppSelectedCard?.name ?? '상대';
        final msg = _pendingTurnMsg ?? (dealt > 0
            ? '$attackerName이(가) $defenderName에게 $dealt 데미지!'
            : 'Miss! 공격이 빗나갔습니다.');
        if (mounted) setState(() => _battleLog = msg);

        await _playAttack(_playerAttackCtrl); // 메시지와 동시 시작

        // 2) 데미지 팝업/피격 깜빡임
        if (mounted) {
          _enemyDamageText = dealt > 0 ? '-$dealt' : 'MISS';
          _showEnemyDamage = true;
          setState(() {});
        }
        _enemyDamageCtrl.reset();
        await _enemyDamageCtrl.forward();        // 팝업 1초
        await _blink(_enemyBlinkCtrl, cycles: 2);

        // 3) 패배 시 퇴장
        if (_opponentHp <= 0) {
          await _playDefeat(_enemyDefeatCtrl);
        }

        // 4) 다음 차례 전 0.6초 대기
        await Future.delayed(const Duration(milliseconds: 600));
        if (mounted) {
          _showEnemyDamage = false;
          setState(() {});
        }
      } else if (playerTookDamage) {
        // 상대가 공격자
        final taken = prevPlayerHp - newPlayerHp;
        final attackerName = _oppSelectedCard?.name ?? '상대';
        final defenderName = _mySelectedCard?.name ?? '나';
        final msg = _pendingTurnMsg ?? (taken > 0
            ? '$attackerName이(가) $defenderName에게 $taken 데미지!'
            : 'Miss! 공격이 빗나갔습니다.');
        if (mounted) setState(() => _battleLog = msg);

        await _playAttack(_enemyAttackCtrl); // 메시지와 동시 시작

        if (mounted) {
          _playerDamageText = taken > 0 ? '-$taken' : 'MISS';
          _showPlayerDamage = true;
          setState(() {});
        }
        _playerDamageCtrl.reset();
        await _playerDamageCtrl.forward();        // 팝업 1초
        await _blink(_playerBlinkCtrl, cycles: 2);

        if (_playerHp <= 0) {
          await _playDefeat(_playerDefeatCtrl);
        }

        await Future.delayed(const Duration(milliseconds: 600));
        if (mounted) {
          _showPlayerDamage = false;
          setState(() {});
        }
      } else {
        // MISS (HP 변화 없음) — 예상 공격자 기준으로 처리
        if (_pendingTurnMsg != null &&
            _pendingTurnMsg!.toLowerCase().contains('miss')) {
          if (_expectedAttackerIsMine) {
            if (mounted) setState(() => _battleLog = _pendingTurnMsg!);
            await _playAttack(_playerAttackCtrl); // 메시지와 동시
            if (mounted) {
              _enemyDamageText = 'MISS';
              _showEnemyDamage = true;
              setState(() {});
            }
            _enemyDamageCtrl.reset();
            await _enemyDamageCtrl.forward();    // MISS 팝업 1초
            await Future.delayed(const Duration(milliseconds: 200));
            if (mounted) {
              _showEnemyDamage = false;
              setState(() {});
            }
          } else {
            if (mounted) setState(() => _battleLog = _pendingTurnMsg!);
            await _playAttack(_enemyAttackCtrl); // 메시지와 동시
            if (mounted) {
              _playerDamageText = 'MISS';
              _showPlayerDamage = true;
              setState(() {});
            }
            _playerDamageCtrl.reset();
            await _playerDamageCtrl.forward();
            await Future.delayed(const Duration(milliseconds: 200));
            if (mounted) {
              _showPlayerDamage = false;
              setState(() {});
            }
          }
          await Future.delayed(const Duration(milliseconds: 600));
        }
      }

      // 턴 토글 및 메시지 초기화
      _expectedAttackerIsMine = !_expectedAttackerIsMine;
      _pendingTurnMsg = null;
    }
    _isAnimating = false;

    // 모든 연출이 끝난 뒤 보류 이벤트/메시지 처리
    await _tryProcessPending();
  }

  // ===== 보류된 nextRound / matchResult / roundResult 처리 =====
  Future<void> _tryProcessPending() async {
    // 1) 라운드 승리 문구를 먼저 출력(애니 완주 후)
    if (_pendingRoundResult != null &&
        !_isAnimating && _statusQueue.isEmpty &&
        !_playerDefeatCtrl.isAnimating && !_enemyDefeatCtrl.isAnimating) {
      if (mounted) setState(() => _battleLog = _pendingRoundResult!);
      _pendingRoundResult = null;
      await Future.delayed(const Duration(milliseconds: 800));
    }

    // 2) nextRound가 있으면 우선 처리
    if (_pendingNextRoundData != null &&
        !_isAnimating && _statusQueue.isEmpty &&
        !_playerDefeatCtrl.isAnimating && !_enemyDefeatCtrl.isAnimating) {
      final data = _pendingNextRoundData;
      _pendingNextRoundData = null;
      _applyNextRound(data);
      return;
    }

    // 3) 최종 결과가 보류 중이면 처리
    if (_pendingMatchResult != null &&
        !_isAnimating && _statusQueue.isEmpty &&
        !_playerDefeatCtrl.isAnimating && !_enemyDefeatCtrl.isAnimating) {
      final msg = _pendingMatchResult!;
      _pendingMatchResult = null;
      await _processMatchResult(msg);
    }
  }

  // ===== nextRound: 애니메이션 중이면 보류 =====
  void _onNextRound(dynamic data) {
    if (_isAnimating || _statusQueue.isNotEmpty ||
        _playerDefeatCtrl.isAnimating || _enemyDefeatCtrl.isAnimating) {
      _pendingNextRoundData = data;
      return;
    }
    _applyNextRound(data);
  }

  // ===== matchResult: 애니메이션 중이면 보류 =====
  void _onMatchResult(dynamic msg) {
    if (_isAnimating || _statusQueue.isNotEmpty ||
        _playerDefeatCtrl.isAnimating || _enemyDefeatCtrl.isAnimating) {
      _pendingMatchResult = msg.toString();
      return;
    }
    _processMatchResult(msg.toString());
  }

  Future<void> _processMatchResult(String msg) async {
    if (!mounted) return;

    // 승/패 판단 (서버 메시지에 내 uid가 포함되면 승리)
    final iWon = msg.contains(widget.userUid);

    setState(() {
      _battleLog = msg;
      _isVictory = iWon;
      _showResultOverlay = true;
    });

    if (iWon) {
      _victoryCtrl.reset();
      await _victoryCtrl.forward();
      await Future.delayed(const Duration(milliseconds: 700));
    } else {
      _defeatCtrl.reset();
      await _defeatCtrl.forward();
      await Future.delayed(const Duration(milliseconds: 700));
    }

    if (!mounted) return;
    Navigator.of(context).pop();
  }

  // ===== 실제 nextRound 반영 =====
  void _applyNextRound(dynamic data) {
    try {
      final map = Map<String, dynamic>.from(data as Map);
      final cardsInfo = Map<String, dynamic>.from(map['cardsInfo'] as Map);
      final pickerId = map['picker']?.toString();
      final myId = SocketService.socket.id;

      final oppRaw = List.from(cardsInfo[myId] as List);
      final myRaw = List.from(
        (cardsInfo.entries.firstWhere((e) => e.key != myId).value as List),
      );

      final newMy  = myRaw.map((j) => InsectCard.fromJson(Map<String, dynamic>.from(j))).toList();
      final newOpp = oppRaw.map((j) => InsectCard.fromJson(Map<String, dynamic>.from(j))).toList();

      final iPick = (pickerId == myId); // 내가 패자면 true

      // 승자(내가 선택 안 함): 내 카드 고정 유지(HP는 서버 값으로 갱신)
      int? lockedIndex;
      InsectCard? lockedCard;
      if (!iPick && _mySelectedCard != null) {
        final idx = _findSameCardIndex(newMy, _mySelectedCard!);
        if (idx != -1) {
          lockedIndex = idx;
          lockedCard  = newMy[idx];
        }
      }

      // 패자: 상대 고정 카드(직전 승리 카드) 하이라이트
      InsectCard? oppLocked;
      if (_oppSelectedCard != null) {
        final idx = _findSameCardIndex(newOpp, _oppSelectedCard!);
        if (idx != -1) oppLocked = newOpp[idx];
      }

      // 다음 라운드 시작 전 초기화
      _playerAttackCtrl.reset();
      _enemyAttackCtrl.reset();
      _playerBlinkCtrl.reset();
      _enemyBlinkCtrl.reset();
      _playerDefeatCtrl.reset();
      _enemyDefeatCtrl.reset();
      _playerDamageCtrl.reset();
      _enemyDamageCtrl.reset();

      setState(() {
        _myRemaining  = newMy;
        _oppRemaining = newOpp;

        _roundNum += 1;
        _inSelection = true;
        _iPickThisRound = iPick;

        if (iPick) {
          _mySelectedIndex = null;
          _mySelectedCard  = null;
          _oppSelectedCard = oppLocked;
          _battleLog = 'Round $_roundNum: 카드를 선택하세요';
        } else {
          _mySelectedIndex = lockedIndex;
          _mySelectedCard  = lockedCard;
          _battleLog = '상대가 곤충을 고르는 중입니다.';
        }

        _showPlayerDamage = false;
        _showEnemyDamage  = false;
        _playerDamageText = '';
        _enemyDamageText  = '';
        _pendingTurnMsg   = null;
        _pendingRoundResult = null;
        _showResultOverlay = false; // 혹시 이전 오버레이가 남아있지 않도록
      });
    } catch (e) {
      setState(() {
        _battleLog = '다음 라운드 데이터 파싱 실패: $e';
      });
    }
  }

  // ===== 내 카드 선택(패자만 호출) =====
  void _pickCardAndSend(int index) {
    if (!_iPickThisRound) return; // 승자는 선택 금지
    setState(() => _mySelectedIndex = index);
    SocketService.selectCard(index);
  }

  // ===== UI 보조 =====
  int _findSameCardIndex(List<InsectCard> list, InsectCard ref) {
    return list.indexWhere((c) => c.name == ref.name && c.type == ref.type);
  }

  Widget _buildHpBar(int current, int max) {
    final m = (max <= 0) ? 1 : max;
    final c = current.clamp(0, m);
    final percent = c / m;
    return Stack(
      children: [
        Container(
          width: 100, height: 8,
          decoration: BoxDecoration(color: Colors.red.shade200, borderRadius: BorderRadius.circular(4)),
        ),
        Container(
          width: 100 * percent, height: 8,
          decoration: BoxDecoration(color: Colors.green, borderRadius: BorderRadius.circular(4)),
        ),
      ],
    );
  }

  Widget _cardTile(InsectCard c, {bool selected = false, bool tappable = false, VoidCallback? onTap}) {
    return GestureDetector(
      onTap: tappable ? onTap : null,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 6, vertical: 8),
        decoration: BoxDecoration(
          border: Border.all(color: selected ? widget.themeColor : Colors.transparent, width: 2),
          borderRadius: BorderRadius.circular(8),
          color: Colors.black87,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Image.file(
                File(c.image),
                width: 100,
                height: 140,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => const Icon(Icons.broken_image, color: Colors.white),
              ),
            ),
            const SizedBox(height: 4),
            Text(c.name, style: const TextStyle(color: Colors.white), overflow: TextOverflow.ellipsis),
            const SizedBox(height: 4),
          ],
        ),
      ),
    );
  }

  // 상대 엔트리(남은 카드 전부) — 고정 카드 하이라이트
  Widget _opponentEntryTile(InsectCard c) {
    final isLocked = (_oppSelectedCard != null &&
        c.name == _oppSelectedCard!.name && c.type == _oppSelectedCard!.type);
    return Stack(
      children: [
        Container(
          margin: const EdgeInsets.symmetric(horizontal: 6, vertical: 8),
          decoration: BoxDecoration(
            border: Border.all(
              color: isLocked ? widget.themeColor : Colors.white24,
              width: isLocked ? 2 : 1,
            ),
            borderRadius: BorderRadius.circular(8),
            color: Colors.black54,
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: Image.file(
              File(c.image),
              width: 100,
              height: 140,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => const Icon(Icons.broken_image, color: Colors.white),
            ),
          ),
        ),
        if (isLocked)
          Positioned(
            right: 8,
            top: 8,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: widget.themeColor.withOpacity(0.9),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Text('고정', style: TextStyle(color: Colors.white, fontSize: 10)),
            ),
          ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final overlayWidth = min(MediaQuery.of(context).size.width * 0.8, 420.0);

    return Scaffold(
      extendBody: true,
      extendBodyBehindAppBar: true,
      resizeToAvoidBottomInset: false,
      body: Stack(
        children: [
          // 배경: 화면 꽉 채우기
          const Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                image: DecorationImage(
                  image: AssetImage('assets/images/background/forest_background.png'),
                  fit: BoxFit.cover,
                  alignment: Alignment.center,
                ),
              ),
            ),
          ),

          // 전경 UI
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                children: [
                  const SizedBox(height: 12),
                  Text('Round $_roundNum', style: const TextStyle(color: Colors.white, fontSize: 20)),
                  const SizedBox(height: 8),

                  // ===== 선택/대기 단계 =====
                  if (_inSelection) ...[
                    const SizedBox(height: 8),
                    Row(
                      children: const [
                        Text('상대 엔트리', style: TextStyle(color: Colors.white70)),
                        SizedBox(width: 6),
                      ],
                    ),
                    const SizedBox(height: 4),
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(children: _oppRemaining.map(_opponentEntryTile).toList()),
                    ),
                    const SizedBox(height: 12),

                    if (_iPickThisRound) ...[
                      const Text('내 카드 선택', style: TextStyle(color: Colors.white)),
                      SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          children: [
                            for (int i = 0; i < _myRemaining.length; i++)
                              _cardTile(
                                _myRemaining[i],
                                selected: _mySelectedIndex == i,
                                tappable: true,
                                onTap: () => _pickCardAndSend(i),
                              ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        _mySelectedIndex == null ? '카드를 탭하여 선택하세요' : '선택 완료! 상대를 기다리는 중…',
                        style: const TextStyle(color: Colors.white70),
                      ),
                    ] else ...[
                      const SizedBox(height: 8),
                      const Text('내 카드(고정)', style: TextStyle(color: Colors.white)),
                      if (_mySelectedCard != null)
                        _cardTile(_mySelectedCard!, selected: true, tappable: false),
                      const SizedBox(height: 8),
                      const Text('상대가 곤충을 고르는 중입니다.', style: TextStyle(color: Colors.white70)),
                    ],
                  ]

                  // ===== 전투 단계 =====
                  else ...[
                    const SizedBox(height: 8),

                    // --- 적 카드(우측 상단) ---
                    Align(
                      alignment: Alignment.topRight,
                      child: FadeTransition(
                        opacity: _enemyDefeatFade,
                        child: SlideTransition(
                          position: _enemyDefeatSlide,
                          child: SlideTransition(
                            position: _enemyAttackSlide,
                            child: FadeTransition(
                              opacity: _enemyBlinkOpacity,
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  if (_oppSelectedCard != null)
                                    Stack(
                                      alignment: Alignment.topCenter,
                                      children: [
                                        Image.file(
                                          File(_oppSelectedCard!.image),
                                          height: 120,
                                          fit: BoxFit.cover,
                                        ),
                                        if (_showEnemyDamage)
                                          SlideTransition(
                                            position: _enemyDamageSlide,
                                            child: FadeTransition(
                                              opacity: _enemyDamageFade,
                                              child: Padding(
                                                padding: const EdgeInsets.only(top: 6),
                                                child: Text(
                                                  _enemyDamageText,
                                                  style: const TextStyle(
                                                    color: Colors.red,
                                                    fontSize: 22,
                                                    fontWeight: FontWeight.bold,
                                                    shadows: [
                                                      Shadow(color: Colors.black, blurRadius: 6, offset: Offset(0, 1)),
                                                      Shadow(color: Colors.black, blurRadius: 6, offset: Offset(0, -1)),
                                                    ],
                                                  ),
                                                ),
                                              ),
                                            ),
                                          ),
                                      ],
                                    ),
                                  const SizedBox(height: 6),
                                  _buildHpBar(_opponentHp, _oppSelectedCard?.health ?? 1),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),

                    const Spacer(),

                    // --- 내 카드(좌측 하단) ---
                    Align(
                      alignment: Alignment.bottomLeft,
                      child: FadeTransition(
                        opacity: _playerDefeatFade,
                        child: SlideTransition(
                          position: _playerDefeatSlide,
                          child: SlideTransition(
                            position: _playerAttackSlide,
                            child: FadeTransition(
                              opacity: _playerBlinkOpacity,
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  if (_mySelectedCard != null)
                                    Stack(
                                      alignment: Alignment.topCenter,
                                      children: [
                                        Image.file(
                                          File(_mySelectedCard!.image),
                                          height: 120,
                                          fit: BoxFit.cover,
                                          errorBuilder: (_, __, ___) =>
                                          const Icon(Icons.broken_image, color: Colors.white),
                                        ),
                                        if (_showPlayerDamage)
                                          SlideTransition(
                                            position: _playerDamageSlide,
                                            child: FadeTransition(
                                              opacity: _playerDamageFade,
                                              child: Padding(
                                                padding: const EdgeInsets.only(top: 6),
                                                child: Text(
                                                  _playerDamageText,
                                                  style: const TextStyle(
                                                    color: Colors.red,
                                                    fontSize: 22,
                                                    fontWeight: FontWeight.bold,
                                                    shadows: [
                                                      Shadow(color: Colors.black, blurRadius: 6, offset: Offset(0, 1)),
                                                      Shadow(color: Colors.black, blurRadius: 6, offset: Offset(0, -1)),
                                                    ],
                                                  ),
                                                ),
                                              ),
                                            ),
                                          ),
                                      ],
                                    ),
                                  const SizedBox(height: 6),
                                  _buildHpBar(_playerHp, _mySelectedCard?.health ?? 1),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 16),
                    Container(
                      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        _battleLog,
                        textAlign: TextAlign.center,
                        style: const TextStyle(color: Colors.black),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),

          // ======= 최종 결과 오버레이 (승리/패배) =======
          if (_showResultOverlay)
            Positioned.fill(
              child: Container(
                color: Colors.black54,
                child: Center(
                  child: SizedBox(
                    width: overlayWidth,
                    child: _isVictory
                        ? FadeTransition(
                      opacity: _victoryFade,
                      child: ScaleTransition(
                        scale: _victoryScale,
                        child: Image.asset(
                          'assets/images/victory.png',
                          fit: BoxFit.contain,
                        ),
                      ),
                    )
                        : FadeTransition(
                      opacity: _defeatFade,
                      child: SlideTransition(
                        position: _defeatSlide,
                        child: Image.asset(
                          'assets/images/defeat.png',
                          fit: BoxFit.contain,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
