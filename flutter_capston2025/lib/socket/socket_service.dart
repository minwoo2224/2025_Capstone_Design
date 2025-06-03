import 'package:socket_io_client/socket_io_client.dart' as IO;
import '../models/insect_card.dart';

class SocketService {
  static late IO.Socket socket;
  static bool _isConnected = false;

  static void connect({
    required Function(List<InsectCard>) onCardsReceived,
    required Function() onMatched,
    required Function() onConnected,
  }) {
    if (_isConnected) {
      print('✅ 이미 연결됨, 콜백 실행');
      onConnected();
      return;
    }

    socket = IO.io('http://52.78.181.93:8080', <String, dynamic>{
      'transports': ['websocket'],
      'autoConnect': false,
    });

    socket.connect();

    socket.onConnect((_) {
      print('✅ Connected to server');
      _isConnected = true;
      onConnected();
    });

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

    socket.on('matched', (msg) {
      print('🎮 매칭 성공: $msg');
      onMatched();
    });

    socket.onDisconnect((_) {
      print('❌ Disconnected from server');
      _isConnected = false;
    });

    socket.on('card_length_error', (msg) {
      print('❗ 서버 오류: $msg');
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
    }).toList();

    socket.emit('joinQueue', {
      'name': username,
      'cards': cardData,
    });
  }

  static void selectCard(int index) {
    socket.emit('selectCard', index);
  }
}
