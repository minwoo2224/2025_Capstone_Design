import 'dart:io';
import 'package:path_provider/path_provider.dart';

// 게스트/유저별로 파일 분리
Future<File> _getLoginFile({bool guest = false}) async {
  final dir = await getApplicationDocumentsDirectory();
  final fileName = guest ? 'guest_login.txt' : 'user_login.txt';
  return File('${dir.path}/$fileName');
}

Future<void> saveLoginInfo(Map<String, String> info, {bool guest = false}) async {
  final file = await _getLoginFile(guest: guest);
  await file.writeAsString(info.entries.map((e) => '${e.key}=${e.value}').join('\n'));
}

Future<Map<String, String>> readLoginInfo({bool guest = false}) async {
  final file = await _getLoginFile(guest: guest);
  if (!(await file.exists())) return {};
  final lines = await file.readAsLines();
  final map = <String, String>{};
  for (var line in lines) {
    if (line.contains('=')) {
      final idx = line.indexOf('=');
      map[line.substring(0, idx)] = line.substring(idx + 1);
    }
  }
  return map;
}

Future<void> clearLoginInfo({bool guest = false}) async {
  final file = await _getLoginFile(guest: guest);
  if (await file.exists()) await file.delete();
}
