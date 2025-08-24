import 'package:socket_io_client/socket_io_client.dart' as IO;
import '../models/insect_card.dart';

class SocketService {
  static late IO.Socket socket;
  static bool _isConnected = false;

  static Function()? _onOpponentReady;
  static Function(InsectCard)? _onOpponentCardReceived;
  static Function(List<InsectCard>, List<InsectCard>)? _onNextRound;

  static void connect({
    required Function(List<InsectCard>) onCardsReceived,
    required Function() onMatched,
    required Function() onConnected,
  }) {
    if (_isConnected) {
      print('✅ 이미 연결됨, 리스너 재등록');

      _registerListeners(
        onCardsReceived: onCardsReceived,
        onMatched: onMatched,
      );

      onConnected();
      return;
    }

    socket = IO.io(
      'http://172.30.1.44:8080',
      <String, dynamic>{
        'transports': ['websocket'],
        'autoConnect': false,
      },
    );

    socket.connect();

    socket.onConnect((_) {
      print('✅ Connected to server');
      _isConnected = true;

      _registerListeners(
        onCardsReceived: onCardsReceived,
        onMatched: onMatched,
      );

      onConnected();
    });

    socket.onDisconnect((_) {
      print('❌ Disconnected from server');
      _isConnected = false;
    });

    socket.on('card_length_error', (msg) {
      print('❗ 서버 오류: $msg');
    });
  }

  static void _registerListeners({
    required Function(List<InsectCard>) onCardsReceived,
    required Function() onMatched,
  }) {
    socket.off('cardsInfo');
    socket.off('matched');
    socket.off('selectCard');
    socket.off('startBattle');
    socket.off('opponentReady');
    socket.off('nextRound');

    socket.on('cardsInfo', (data) {
      print('🃏 카드 정보 수신: $data');
      try {
        final cards = (data as List<dynamic>).map((card) {
          return InsectCard.fromJson(card as Map<String, dynamic>);
        }).toList();
        onCardsReceived(cards);
      } catch (e) {
        print('⚠ 카드 변환 실패: $e');
      }
    });

    socket.on('matched', (_) {
      print('🎮 매칭 성공: select card!');
      onMatched();
    });

    socket.on('startBattle', (data) {
      print('⚔ 서버로부터 배틀 시작 신호 수신: $data');

      final myId = socket.id;
      if (data != null && myId != null && data[myId] != null) {
        final cardJson = data[myId] as Map<String, dynamic>;
        final opponentCard = InsectCard.fromJson(cardJson);
        if (_onOpponentCardReceived != null) {
          _onOpponentCardReceived!(opponentCard);
        }
      } else {
        print('⚠ startBattle 응답에 카드 데이터 없음');
      }
    });

    socket.on('opponentReady', (_) {
      print('🎯 상대방도 준비 완료');
      if (_onOpponentReady != null) _onOpponentReady!();
    });

    socket.on('nextRound', (data) {
      print('🔄 다음 라운드 정보 수신: $data');
      try {
        final myId = socket.id;
        final cardsInfo = data['cardsInfo'];
        if (cardsInfo != null && cardsInfo[myId] != null) {
          final opponentCardsRaw = cardsInfo[myId] as List<dynamic>;
          final opponentCards = opponentCardsRaw
              .map((card) => InsectCard.fromJson(card))
              .toList();

          final myCardsRaw = cardsInfo.entries
              .firstWhere((entry) => entry.key != myId)
              .value as List<dynamic>;
          final myCards = myCardsRaw
              .map((card) => InsectCard.fromJson(card))
              .toList();

          if (_onNextRound != null) {
            _onNextRound!(myCards, opponentCards);
          }
        }
      } catch (e) {
        print('⚠ nextRound 카드 파싱 실패: $e');
      }
    });
  }

  static void sendCardData(String uid, List<InsectCard> cards) {
    sendCards(uid, cards);
  }

  static void sendCards(String username, List<InsectCard> cards) {
    final cardData = cards.map((card) => {
      'name': card.name,
      'hp': card.health,
      'attack': card.attack,
      'defend': card.defense,
      'speed': card.speed,
      'type': card.type,
      'image': card.image,
    }).toList();

    print('📤 카드 전송: $cardData');

    socket.emit('joinQueue', {
      'name': username,
      'cards': cardData,
    });
  }

  static void selectCard(int index) {
    print('🖐️ 카드 선택: $index');
    socket.emit('selectCard', index);
  }

  static void sendSelectedCard(InsectCard card) {
    final cardJson = {
      'name': card.name,
      'hp': card.health,
      'attack': card.attack,
      'defend': card.defense,
      'speed': card.speed,
      'type': card.type,
      'image': card.image,
    };
    print('📨 선택된 카드 전송: $cardJson');
    socket.emit('selectedCard', cardJson);
  }

  static void setOpponentReadyCallback(Function() onReady) {
    _onOpponentReady = onReady;
  }

  static void setOpponentCardCallback(Function(InsectCard) onCardReceived) {
    _onOpponentCardReceived = onCardReceived;
  }

  static void setNextRoundCallback(Function(List<InsectCard>, List<InsectCard>) onNext) {
    _onNextRound = onNext;
  }
}
