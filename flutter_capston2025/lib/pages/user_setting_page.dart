import 'package:flutter/material.dart';
import 'package:flutter_capston2025/widgets/nickname_editor.dart';

class UserSettingPage extends StatefulWidget {
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
  State<UserSettingPage> createState() => _UserSettingPageState();
}

class _UserSettingPageState extends State<UserSettingPage> {
  bool _isMale = true; // 남자(기본값), false면 여자

  @override
  Widget build(BuildContext context) {
    final isGuest = widget.email.toLowerCase() == 'guest@example.com';
    final displayUserNumber = widget.userData?['userNumber']?.toString() ?? '알 수 없음';

    // 성별에 따라 이미지 경로를 다르게
    final userImage = _isMale
        ? 'assets/images/User_sex/BugStrike_user_images_male.png'
        : 'assets/images/User_sex/BugStrike_user_images_female.png';

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: const Text("설정"),
        backgroundColor: widget.themeColor,
        centerTitle: true,
        actions: [
          // 오른쪽에 남녀 토글
          Row(
            children: [
              const Text("남", style: TextStyle(color: Colors.white, fontSize: 15)),
              Switch(
                value: !_isMale, // true면 여자로 토글
                activeColor: Colors.pinkAccent,
                inactiveThumbColor: Colors.blue,
                onChanged: (v) {
                  setState(() {
                    _isMale = !v; // false면 남자, true면 여자
                  });
                },
              ),
              const Text("여", style: TextStyle(color: Colors.white, fontSize: 15)),
              const SizedBox(width: 8),
            ],
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.only(bottom: 24),
          child: Column(
            children: [
              const SizedBox(height: 30),
              SizedBox(
                height: 340,
                child: Image.asset(userImage, fit: BoxFit.contain),
              ),
              const SizedBox(height: 10),
              if (isGuest)
                const Text("비회원입니다.",
                    style: TextStyle(color: Colors.grey, fontSize: 14, fontStyle: FontStyle.italic)),
              const SizedBox(height: 10),
              NicknameEditor(
                isGuest: isGuest,
                userUid: widget.userUid,
                initialNickname: widget.userData?['nickname']?.toString() ?? '',
                refreshUserData: widget.refreshUserData,
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
                      _infoRow("이메일", widget.email),
                      const SizedBox(height: 10),
                      _infoRow("회원 번호", displayUserNumber),
                      const SizedBox(height: 10),
                      _infoRow("계정 생성일", widget.createDate),
                      const SizedBox(height: 10),
                      _infoRow("잡은 곤충 개수", "${widget.insectCount}개"),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 30),
              Center(
                child: ElevatedButton(
                  onPressed: widget.onLogout,
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
