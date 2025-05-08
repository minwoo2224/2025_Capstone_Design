import 'package:socket_io_client/socket_io_client.dart' as IO;
import '../models/insect_card.dart';

class SocketService {
  static late IO.Socket socket;

  static void connect() {
    socket = IO.io('http://43.203.208.60:8080/', IO.OptionBuilder() //서버 주소
        .setTransports(['websocket'])
        .disableAutoConnect()
        .build());

    socket.connect();

    socket.onConnect((_) => print("✅ 서버 연결됨"));
    socket.onDisconnect((_) => print("❌ 연결 끊김"));

    socket.on("updateStatus", (data) {
      print("🌀 상태 업데이트: ${data['self']} 체력 ${data['selfHp']} / ${data['enemy']} 체력 ${data['enemyHp']}");
    });

    socket.on("updateResult", (msg) {
      print("🏆 결과: $msg");
    });

    socket.onError((data) => print("⚠️ 에러 발생: $data"));
  }

  static void joinQueue(InsectCard card) {
    final playerData = {
      "name": card.name,
      "attack": card.attack,
      "defend": card.defense,
      "hp": card.health,
      "speed": card.speed,
    };

    socket.emit("joinQueue", playerData);
    print("🛰 joinQueue 요청 전송됨");
  }

  // ✅ 여기에 추가!
  static void sendSingleCard(InsectCard card) {
    final cardData = {
      "name": card.name,
      "attack": card.attack,
      "defend": card.defense,
      "hp": card.health,
      "speed": card.speed,
    };

    socket.emit("sendSingleCard", cardData);
    print("📤 카드 전송됨: $cardData");
  }
}
