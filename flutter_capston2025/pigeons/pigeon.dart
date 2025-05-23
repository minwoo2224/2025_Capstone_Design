import 'package:pigeon/pigeon.dart';

/// Flutter → Android 또는 iOS 에 전달할 사용자 정보 클래스
class PigeonUserDetails {
  String? uid;
  String? email;
  String? displayName;
}

/// Flutter → 플랫폼 호출을 위한 API 정의
@HostApi()
abstract class AuthBridge {
  /// 로그인된 사용자 정보를 native로 전달
  void sendUserDetails(PigeonUserDetails details);
}
