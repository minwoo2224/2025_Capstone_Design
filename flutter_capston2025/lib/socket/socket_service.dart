import 'package:socket_io_client/socket_io_client.dart' as IO;
import '../models/insect_card.dart';

class SocketService {
  static late IO.Socket socket;

  static void connect() {
    socket = IO.io('https://temp_url', IO.OptionBuilder() //나중에 서버 url로 변경
        .setTransports(['websocket']) // websocket 사용
        .build());

    socket.connect();

    socket.onConnect((_) {
      print("✅ 서버 연결됨");
    });

    socket.onDisconnect((_) {
      print("❌ 서버 연결 끊김");
    });

    socket.onError((data) {
      print("⚠️ 에러 발생: $data");
    });
  }

  static void sendSelectedCards(List<InsectCard> cards) {
    final jsonList = cards.map((card) => card.toJson()).toList();
    socket.emit("selectedCards", jsonList);
    print("🛰 선택된 카드 서버에 전송함");
  }

  static void sendSingleCard(InsectCard card) {
    socket.emit("selectedCard", card.toJson());
    print("🛰 단일 카드 서버에 전송함");
  }
}
