import 'dart:io';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'storage/login_storage.dart'; // 위에서 정의한 txt 저장/삭제 함수
import 'pages/camera_page.dart';
import 'pages/collection_page.dart';
import 'pages/search_page.dart';
import 'pages/game_page.dart';
import 'pages/login_page.dart';
import 'pages/user_setting_page.dart';

class MainNavigation extends StatefulWidget {
  final int selectedIndex;
  final bool isGuest;

  const MainNavigation({
    super.key,
    this.selectedIndex = 0,
    this.isGuest = false,
  });

  @override
  State<MainNavigation> createState() => _MainNavigationState();
}

class _MainNavigationState extends State<MainNavigation> {
  late int _selectedIndex;
  late bool _isGuest;
  Map<String, String> _loginInfo = {};
  Color _themeColor = Colors.deepPurple;
  int _insectCount = 0;

  @override
  void initState() {
    super.initState();
    _selectedIndex = widget.selectedIndex;
    _isGuest = widget.isGuest;
    _loadLoginInfo();
  }

  Future<void> _loadLoginInfo() async {
    Map<String, String> info = {};
    if (_isGuest) {
      info = await readLoginInfo(guest: true);
    } else {
      info = await readLoginInfo(guest: false);
    }
    setState(() {
      _loginInfo = info;
    });
  }

  Future<void> _onLogout() async {
    if (_isGuest) {
      await clearLoginInfo(guest: true);
    } else {
      await clearLoginInfo(guest: false);
    }
    if (!mounted) return;
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => const LoginPage()),
          (route) => false,
    );
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    // 로딩 중에는 로딩표시
    if (_loginInfo.isEmpty) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    final List<Widget> pages = [
      CameraPage(themeColor: _themeColor, onPhotoTaken: () {}),
      CollectionPage(themeColor: _themeColor, images: const [], previewColumns: 2, onPreviewSetting: () {}, onImageDeleted: () {}),
      SearchPage(themeColor: _themeColor),
      GamePage(themeColor: _themeColor),
      UserSettingPage(
        email: _loginInfo['email'] ?? '알 수 없음',
        userUid: _loginInfo['uid'] ?? '알 수 없음',
        createDate: _loginInfo['loginDate']?.split('T').first ?? '알 수 없음',
        insectCount: _insectCount,
        themeColor: _themeColor,
        onLogout: _onLogout,
        userData: _loginInfo,
        refreshUserData: _loadLoginInfo,
      ),
    ];

    return Scaffold(
      body: pages[_selectedIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        selectedItemColor: _themeColor,
        unselectedItemColor: Colors.grey,
        type: BottomNavigationBarType.fixed,
        onTap: _onItemTapped,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.camera_alt), label: '촬영'),
          BottomNavigationBarItem(icon: Icon(Icons.bookmark), label: '도감'),
          BottomNavigationBarItem(icon: Icon(Icons.search), label: '검색'),
          BottomNavigationBarItem(icon: Icon(Icons.sports_kabaddi), label: '게임'),
          BottomNavigationBarItem(icon: Icon(Icons.settings), label: '설정'),
        ],
      ),
    );
  }
}
