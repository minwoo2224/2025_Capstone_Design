import 'package:flutter/material.dart';
import 'package:flutter_capston2025/pages/login_page.dart'; // 절대 경로 임포트 유지

class UserSettingPage extends StatelessWidget {
  final String email;
  final String userUid;
  final String createDate; // 이미 적절히 가공된 String을 받는다고 가정
  final int insectCount;
  final Color themeColor;
  final VoidCallback onLogout;
  final Map<String, dynamic>? userData; // Map<String, dynamic>으로 받도록 유지
  final VoidCallback? refreshUserData; // 데이터 새로고침 콜백

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
    print('DEBUG: user_setting_page.dart - received createDate: $createDate');
    print('DEBUG: user_setting_page.dart - Type of received createDate: ${createDate.runtimeType}');

    // 필수 데이터가 없을 경우 (예: 초기 로딩 오류 또는 사용자 정보가 제대로 전달되지 않은 경우)
    // 로그인 페이지로 강제 이동하여 사용자에게 재로그인을 유도합니다.
    if (email == '알 수 없음' || userUid == '알 수 없음') {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        // 현재 라우트 스택에 로그인 페이지가 이미 있다면 중복 푸시 방지
        if (ModalRoute.of(context)?.settings.name != '/') {
          Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(builder: (_) => const LoginPage()),
                (route) => false,
          );
        }
      });
      // 데이터가 없는 상태에서는 빈 위젯을 반환하여 렌더링 오류를 방지
      return const SizedBox();
    }

    final isGuest = email.toLowerCase() == 'guest@example.com';

    // userData 맵에서 'userNumber' 필드를 안전하게 가져옵니다.
    // 필드가 없거나 null일 경우 '알 수 없음'으로 표시합니다.
    final String displayUserNumber = userData?['userNumber']?.toString() ?? '알 수 없음';


    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: const Text("설정"),
        backgroundColor: themeColor,
        centerTitle: true,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.only(bottom: 24),
            child: Column(
              children: [
                const SizedBox(height: 30),
                // 캐릭터 이미지
                SizedBox(
                  height: 340,
                  child: Image.asset(
                    'assets/images/BugStrike_user_images.png',
                    fit: BoxFit.contain,
                  ),
                ),
                // 게스트 사용자일 경우 추가 정보 표시
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
                // 사용자 정보 카드
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
                        // 'createDate'는 Firebase의 'joinDate' 또는 로컬의 'loginDate' 중 사용
                        _infoRow("계정 생성일", createDate), // createDate가 이미 가공된 String이므로 별도 처리 불필요
                        const SizedBox(height: 10),
                        _infoRow("잡은 곤충 개수", "$insectCount개"),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 30),
                // 로그아웃 버튼
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
      ),
    );
  }

  // 정보 표시를 위한 헬퍼 위젯
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