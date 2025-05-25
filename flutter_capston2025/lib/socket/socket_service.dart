import 'package:socket_io_client/socket_io_client.dart' as IO;
import '../models/insect_card.dart';

class SocketService {
  static late IO.Socket socket;

  // 서버 IP로 변경
  static void connect() {
    socket = IO.io('http://localhost:8080', <String, dynamic>{
      'transports': ['websocket'],
      'autoConnect': false,
    });

    socket.connect();

    socket.onConnect((_) {
      print('✅ Connected to server');
    });

    socket.onDisconnect((_) {
      print('❌ Disconnected from server');
    });

    socket.on('card_length_error', (msg) {
      print('❗ 서버 오류: $msg');
    });

    socket.on('matched', (msg) {
      print('🎮 매칭 성공: $msg');
    });

    socket.on('matchResult', (msg) {
      print('🏁 결과: $msg');
    });

    socket.on('nextRound', (data) {
      print('🔁 다음 라운드 정보: $data');
    });

    socket.on('cardsInfo', (data) {
      print('🃏 상대 카드 정보: $data');
    });
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

  static void sendCardData(String uid, List<InsectCard> cards) {
    sendCards(uid, cards);
  }

  static void selectCard(int index) {
    socket.emit('selectCard', index);
  }
}
