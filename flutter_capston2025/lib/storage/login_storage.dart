  import 'dart:io';
  import 'dart:convert'; // jsonEncode, jsonDecode를 위해 임포트
  import 'package:path_provider/path_provider.dart';

  // 게스트/유저별로 파일 분리
  Future<File> _getLoginFile({bool guest = false}) async {
    final dir = await getApplicationDocumentsDirectory();
    final fileName = guest ? 'guest_login.json' : 'user_login.json'; // .txt 대신 .json 사용
    return File('${dir.path}/$fileName');
  }

  // Map<String, dynamic>을 저장하도록 변경
  Future<void> saveLoginInfo(Map<String, dynamic> info, {bool guest = false}) async {
    final file = await _getLoginFile(guest: guest);
    final jsonString = json.encode(info); // Map을 JSON 문자열로 인코딩

    // DEBUG: 저장될 내용 전체 출력
    print('DEBUG (LoginStorage): Saving to ${file.path}');
    print('DEBUG (LoginStorage): Content to be saved:\n$jsonString');
    print('DEBUG (LoginStorage): Type of content to be saved: ${jsonString.runtimeType}');

    await file.writeAsString(jsonString);
    print('로그인 정보 저장 완료: ${file.path}');
  }

  // Map<String, dynamic>을 읽어오도록 변경
  Future<Map<String, dynamic>> readLoginInfo({bool guest = false}) async {
    final file = await _getLoginFile(guest: guest);
    if (!(await file.exists())) {
      print('로그인 파일 없음: ${file.path}');
      return {};
    }
    try {
      final jsonString = await file.readAsString();
      final Map<String, dynamic> map = json.decode(jsonString); // JSON 문자열을 Map으로 디코딩
      print('로그인 정보 읽기 성공: ${file.path}');
      print('DEBUG (LoginStorage): Saving to ${file.path}');
      print('DEBUG (LoginStorage): Content to be saved:\n$jsonString');
      print('DEBUG (LoginStorage): Type of content to be saved: ${jsonString.runtimeType}');
      return map;
    } catch (e) {
      // JSON 파싱 오류나 기타 읽기 오류가 발생하면 파일 삭제 후 빈 맵 반환
      print('로그인 정보 읽기 오류 (파일 손상 가능성): $e');
      await file.delete();
      print('로그인 정보 파일 삭제됨: ${file.path}');
      return {};
    }
  }

  Future<void> clearLoginInfo({bool guest = false}) async {
    final file = await _getLoginFile(guest: guest);
    if (await file.exists()) await file.delete();
    print('로그인 정보 삭제: ${file.path}');
  }
