import 'package:shared_preferences/shared_preferences.dart';

Future<bool> canEditNickname() async {
  final prefs = await SharedPreferences.getInstance();
  final today = DateTime.now().toIso8601String().substring(0, 10);
  final lastEdit = prefs.getString('last_nickname_edit') ?? '';
  return lastEdit != today;
}

Future<void> markNicknameEditedToday() async {
  final prefs = await SharedPreferences.getInstance();
  final today = DateTime.now().toIso8601String().substring(0, 10);
  await prefs.setString('last_nickname_edit', today);
}
