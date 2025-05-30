import 'package:flutter/material.dart';
import 'package:flutter_capston2025/widgets/nickname_editor.dart';

class UserSettingPage extends StatelessWidget {
  final String email;
  final String userUid;
  final String createDate;
  final int insectCount;
  final Color themeColor;
  final VoidCallback onLogout;
  final Map<String, dynamic>? userData;
  final VoidCallback? refreshUserData;

  const UserSettingPage({
    super.key,
    required this.email,
    required this.userUid,
    required this.createDate,
    required this.insectCount,
    required this.themeColor,
    required this.onLogout,
    this.userData,
    this.refreshUserData,
  });

  @override
  Widget build(BuildContext context) {
    final isGuest = email.toLowerCase() == 'guest@example.com';
    final displayUserNumber = userData?['userNumber']?.toString() ?? '알 수 없음';

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: const Text("설정"),
        backgroundColor: themeColor,
        centerTitle: true,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.only(bottom: 24),
          child: Column(
            children: [
              const SizedBox(height: 30),
              SizedBox(
                height: 340,
                child: Image.asset('assets/images/BugStrike_user_images.png', fit: BoxFit.contain),
              ),
              const SizedBox(height: 10),
              if (isGuest)
                const Text("비회원입니다.",
                    style: TextStyle(color: Colors.grey, fontSize: 14, fontStyle: FontStyle.italic)),
              const SizedBox(height: 10),
              NicknameEditor(
                isGuest: isGuest,
                userUid: userUid,
                initialNickname: userData?['nickname']?.toString() ?? '',
                refreshUserData: refreshUserData,
              ),
              Card(
                color: Colors.white12,
                margin: const EdgeInsets.symmetric(horizontal: 30, vertical: 8),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 18),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _infoRow("이메일", email),
                      const SizedBox(height: 10),
                      _infoRow("회원 번호", displayUserNumber),
                      const SizedBox(height: 10),
                      _infoRow("계정 생성일", createDate),
                      const SizedBox(height: 10),
                      _infoRow("잡은 곤충 개수", "$insectCount개"),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 30),
              Center(
                child: ElevatedButton(
                  onPressed: onLogout,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.redAccent,
                    padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: const Text('로그아웃', style: TextStyle(fontSize: 16)),
                ),
              ),
              const SizedBox(height: 36),
            ],
          ),
        ),
      ),
    );
  }

  Widget _infoRow(String title, String value) {
    return Row(
      children: [
        Text(
          "$title: ",
          style: const TextStyle(
            color: Colors.amber,
            fontSize: 17,
            fontWeight: FontWeight.bold,
          ),
        ),
        Flexible(
          child: Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 17,
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}
