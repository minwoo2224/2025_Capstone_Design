import 'package:flutter/material.dart';
import 'package:flutter_capston2025/widgets/nickname_editor.dart';
import '../theme/app_theme.dart';
import '../main.dart' show themeController;
import '../widgets/themed_background.dart';

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
    final isDarkTheme = Theme.of(context).brightness == Brightness.dark;

    // 텍스트/아이콘 공통 색
    final titleColor   = isDarkTheme ? Colors.white : Colors.black87;
    final subTextColor = isDarkTheme ? Colors.white70 : Colors.black54;
    final cardColor    = isDarkTheme ? Colors.white12 : Colors.black12;

    final isGuest = widget.email.toLowerCase() == 'guest@example.com';
    final displayUserNumber = widget.userData?['userNumber']?.toString() ?? '알 수 없음';

    final userImage = _isMale
        ? 'assets/images/User_sex/BugStrike_user_images_male.png'
        : 'assets/images/User_sex/BugStrike_user_images_female.png';

    return Scaffold(
      // 배경은 테마에 맡기고, 종이테마는 ThemedBackground가 그려줌
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,

      appBar: AppBar(
        // ✅ 다크만 기존 보라색, 그 외엔 테마 기본(app_theme.dart) 색
        backgroundColor: isDarkTheme
            ? widget.themeColor
            : Theme.of(context).appBarTheme.backgroundColor,
        foregroundColor: isDarkTheme
            ? Colors.white
            : Theme.of(context).appBarTheme.foregroundColor,
        centerTitle: true,
        title: const Text("설정"),
        leading: IconButton(
          icon: const Icon(Icons.palette_outlined),
          onPressed: _showThemeSheet,
        ),
        actions: [
          Row(
            children: [
              Text("남", style: TextStyle(color: titleColor, fontSize: 15)),
              Switch(
                value: !_isMale,
                activeColor: Colors.pinkAccent,
                inactiveThumbColor: Colors.blue,
                onChanged: (v) => setState(() => _isMale = !v),
              ),
              Text("여", style: TextStyle(color: titleColor, fontSize: 15)),
              const SizedBox(width: 8),
            ],
          ),
        ],
      ),

      body: ThemedBackground( // ✅ 종이 테마 배경
        child: SafeArea(
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
                  Text(
                    "비회원입니다.",
                    style: TextStyle(color: subTextColor, fontSize: 14, fontStyle: FontStyle.italic),
                  ),

                const SizedBox(height: 10),

                Theme(
                  data: Theme.of(context).copyWith(
                    elevatedButtonTheme: ElevatedButtonThemeData(
                      style: ElevatedButton.styleFrom(
                        foregroundColor: Colors.white, // ✅ 라벨/아이콘 흰색
                      ),
                    ),
                  ),
                  child: NicknameEditor(
                    isGuest: isGuest,
                    userUid: widget.userUid,
                    initialNickname: widget.userData?['nickname']?.toString() ?? '',
                    refreshUserData: widget.refreshUserData,
                  ),
                ),

                Card(
                  color: cardColor, // ✅ 테마에 맞춘 카드 배경
                  margin: const EdgeInsets.symmetric(horizontal: 30, vertical: 8),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 18),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _infoRow(context, "이메일", widget.email),
                        const SizedBox(height: 10),
                        _infoRow(context, "회원 번호", displayUserNumber),
                        const SizedBox(height: 10),
                        _infoRow(context, "계정 생성일", widget.createDate),
                        const SizedBox(height: 10),
                        _infoRow(context, "잡은 곤충 개수", "${widget.insectCount}개"),
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
                      foregroundColor: Colors.white,
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

  void _showThemeSheet() {
    showModalBottomSheet(
      context: context,
      builder: (_) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.dark_mode),
              title: const Text('검정색(다크)'),
              onTap: () async {
                await themeController.setTheme(AppTheme.dark);
                if (mounted) Navigator.pop(context);
                setState(() {});
              },
            ),
            ListTile(
              leading: const Icon(Icons.menu_book_outlined),
              title: const Text('종이 질감'),
              onTap: () async {
                await themeController.setTheme(AppTheme.paper);
                if (mounted) Navigator.pop(context);
                setState(() {});
              },
            ),
            ListTile(
              leading: const Icon(Icons.light_mode),
              title: const Text('하얀색(라이트)'),
              onTap: () async {
                await themeController.setTheme(AppTheme.white);
                if (mounted) Navigator.pop(context);
                setState(() {});
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _infoRow(BuildContext context, String title, String value) {
    final primary = Theme.of(context).colorScheme.primary;
    final text    = Theme.of(context).brightness == Brightness.dark
        ? Colors.white
        : Colors.black87;

    return Row(
      children: [
        Text(
          "$title: ",
          style: TextStyle(
            color: primary,
            fontSize: 17,
            fontWeight: FontWeight.bold,
          ),
        ),
        Flexible(
          child: Text(
            value,
            style: TextStyle(
              color: text,
              fontSize: 17,
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}
