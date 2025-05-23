import 'dart:io';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'pages/camera_page.dart';
import 'pages/collection_page.dart';
import 'pages/search_page.dart';
import 'pages/game_page.dart';
import 'pages/user_setting_page.dart';
import 'pages/login_page.dart'; // LoginPage import 추가

class MainNavigation extends StatefulWidget {
  final int selectedIndex;
  const MainNavigation({super.key, this.selectedIndex = 0});

  @override
  State<MainNavigation> createState() => _MainNavigationState();
}

class _MainNavigationState extends State<MainNavigation> {
  late int _selectedIndex;
  Color _themeColor = Colors.deepPurple;
  List<File> _images = [];
  int _previewColumns = 2;

  @override
  void initState() {
    super.initState();
    _selectedIndex = widget.selectedIndex;
    // TODO: _loadImages(), _loadThemeColor() 등 데이터 동기화 함수 필요시 추가
  }

  // 실제 이미지 새로고침 함수 예시
  Future<void> _loadImages() async {
    // 예시: setState(() => _images = ...);
  }

  // 도감 갤러리 프리뷰 컬럼 변경
  void _onPreviewSetting(int columns) {
    setState(() {
      _previewColumns = columns;
    });
  }

  // 갤러리 이미지 삭제 후 리스트 갱신
  void _onImageDeleted() {
    // 예시: setState(() => _images = ...);
  }

  // 로그아웃 기능 구현
  Future<void> _onLogout() async {
    await FirebaseAuth.instance.signOut();
    if (!mounted) return;
    setState(() {}); // 강제 리렌더링(로그인/로그아웃 반영)
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    final pages = [
      CameraPage(
        themeColor: _themeColor,
        onPhotoTaken: _loadImages,
      ),
      CollectionPage(
        themeColor: _themeColor,
        images: _images,
        previewColumns: _previewColumns,
        onPreviewSetting: () => _onPreviewSetting(_previewColumns),
        onImageDeleted: _onImageDeleted,
      ),
      SearchPage(themeColor: _themeColor),
      GamePage(themeColor: _themeColor),
      // 👇 설정(마이페이지)탭에서 로그인 여부 분기
      user == null
          ? LoginPage() // 로그인 안 되어 있으면 로그인 화면
          : UserSettingPage(
        email: user.email ?? '알 수 없음',
        themeColor: _themeColor,
        onLogout: _onLogout,
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
