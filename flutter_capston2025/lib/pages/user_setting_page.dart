import 'dart:io';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

// 곤충마스터 이미지 파일 경로
const String masterImagePath = '/mnt/data/e0cddea5-3594-4535-a84c-14e9d787c156.png';

class UserSettingPage extends StatelessWidget {
  final String email;
  final Color themeColor;
  final VoidCallback onLogout;

  // 임시 값 (실제 데이터 연동 시 DB에서 가져오기)
  final int userNumber = 1; // UID처럼 1번부터
  final int insectCount = 0;

  UserSettingPage({
    super.key,
    required this.email,
    required this.themeColor,
    required this.onLogout,
  });

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    // 계정 생성일 파싱
    String createDate = "알 수 없음";
    if (user != null && user.metadata.creationTime != null) {
      final date = user.metadata.creationTime!;
      createDate = "${date.year}년 ${date.month}월 ${date.day}일";
    }

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
            // 곤충마스터 이미지
            SizedBox(
              height: MediaQuery.of(context).size.height * 0.4, // 2/5 비율
              child: Image.file(
                File(masterImagePath),
                fit: BoxFit.contain,
              ),
            ),
            const SizedBox(height: 10),
            // 정보 카드
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
                    _infoRow("고유 UID", "${userNumber.toString().padLeft(6, '0')}번"),
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
        Text("$title: ",
            style: const TextStyle(
              color: Colors.amber,
              fontSize: 17,
              fontWeight: FontWeight.bold,
            )),
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
