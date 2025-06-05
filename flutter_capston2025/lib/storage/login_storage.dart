import 'dart:io';
import 'dart:convert';
import 'package:path_provider/path_provider.dart';

// 닉네임 txt에 저장 (항상 최신 닉네임 1개만 저장)
Future<void> saveNicknameToTxt(String nickname, {bool guest = false}) async {
  final dir = await getApplicationDocumentsDirectory();
  final fileName = guest ? 'guest_nickname.txt' : 'user_nickname.txt';
  final file = File('${dir.path}/$fileName');
  await file.writeAsString(nickname);
}

// txt에서 닉네임 읽어오기
Future<String> readNicknameFromTxt({bool guest = false}) async {
  final dir = await getApplicationDocumentsDirectory();
  final fileName = guest ? 'guest_nickname.txt' : 'user_nickname.txt';
  final file = File('${dir.path}/$fileName');
  if (await file.exists()) {
    return await file.readAsString();
  }
  return '';
}

// 기존 로그인 정보 저장/로드 함수
Future<File> _getLoginFile({bool guest = false}) async {
  final dir = await getApplicationDocumentsDirectory();
  final fileName = guest ? 'guest_login.json' : 'user_login.json';
  return File('${dir.path}/$fileName');
}

Future<void> saveLoginInfo(Map<String, dynamic> info, {bool guest = false}) async {
  final file = await _getLoginFile(guest: guest);
  final jsonString = json.encode(info);
  await file.writeAsString(jsonString);

  // 닉네임도 info에 있으면 txt에 저장(회원가입/로그인 시 사용)
  if (info['nickname'] != null && info['nickname'].toString().isNotEmpty) {
    await saveNicknameToTxt(info['nickname'].toString(), guest: guest);
  }
}

Future<Map<String, dynamic>> readLoginInfo({bool guest = false}) async {
  final file = await _getLoginFile(guest: guest);
  if (!(await file.exists())) {
    return {};
  }
  try {
    final jsonString = await file.readAsString();
    final Map<String, dynamic> map = json.decode(jsonString);
    return map;
  } catch (e) {
    await file.delete();
    return {};
  }
}

Future<void> clearLoginInfo({bool guest = false}) async {
  final file = await _getLoginFile(guest: guest);
  if (await file.exists()) await file.delete();
}
