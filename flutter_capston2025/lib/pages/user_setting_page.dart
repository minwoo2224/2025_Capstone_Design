import 'dart:io';
import 'package:flutter/material.dart';

class UserSettingPage extends StatelessWidget {
  final String email;
  final String userUid;
  final String createDate;
  final int insectCount;
  final Color themeColor;
  final VoidCallback onLogout;
  final String masterImageAsset;

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
    this.masterImageAsset = 'assets/images/BugStrike_user_images.png',
    this.userData,
    this.refreshUserData,
  });

  @override
  Widget build(BuildContext context) {
    final isGuest = email.toLowerCase() == 'guest@example.com';

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: const Text("설정"),
        backgroundColor: themeColor,
        centerTitle: true,
      ),
      body: Center(
        child: Column(
          children: [
            const SizedBox(height: 30),
            SizedBox(
              height: MediaQuery.of(context).size.height * 0.4,
              child: Image.asset(
                masterImageAsset,
                fit: BoxFit.contain,
              ),
            ),
            if (isGuest) ...[
              const SizedBox(height: 8),
              const Text(
                "비회원입니다.",
                style: TextStyle(
                  color: Colors.grey,
                  fontSize: 14,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ],
            const SizedBox(height: 10),
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
                    _infoRow("고유 UID", userUid),
                    const SizedBox(height: 10),
                    _infoRow("계정 생성일", createDate),
                    const SizedBox(height: 10),
                    _infoRow("잡은 곤충 개수", "$insectCount개"),
                  ],
                ),
              ),
            ),
            const Spacer(),
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
