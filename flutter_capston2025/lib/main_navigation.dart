import 'dart:io';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;

import 'pages/camera_page.dart';
import 'pages/collection_page.dart';
import 'pages/search_page.dart';
import 'pages/game_page.dart';
import 'pages/user_setting_page.dart';
import 'pages/login_page.dart';

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
  Map<String, dynamic>? _guestUserData;

  @override
  void initState() {
    super.initState();
    _selectedIndex = widget.selectedIndex;
    _loadImages();
    _loadThemeColor();
    _loadGuestDataIfNeeded();
  }

  Future<void> _loadImages() async {
    final dir = await getApplicationDocumentsDirectory();
    final photoDir = Directory('${dir.path}/insect_photos');
    if (await photoDir.exists()) {
      final files = photoDir
          .listSync()
          .whereType<File>()
          .where((file) => path.basename(file.path).contains("insect_"))
          .toList();
      setState(() {
        _images = files;
      });
    }
  }

  Future<void> _loadThemeColor() async {
    final prefs = await SharedPreferences.getInstance();
    final colorValue = prefs.getInt('themeColor');
    if (colorValue != null) {
      setState(() {
        _themeColor = Color(colorValue);
      });
    }
  }

  Future<void> _loadGuestDataIfNeeded() async {
    final prefs = await SharedPreferences.getInstance();
    final email = prefs.getString('email');
    if (email == 'guest@example.com') {
      setState(() {
        _guestUserData = {
          'uid': prefs.getString('uid') ?? 'guest_uid',
          'email': email,
          'joinDate': prefs.getString('joinDate') ?? '',
          'insectCount': prefs.getInt('insectCount') ?? 0,
          'userNumber': prefs.getString('userNumber') ?? '000000',
        };
      });
    }
  }

  Future<void> _onLogout() async {
    await FirebaseAuth.instance.signOut();
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
    setState(() {
      _guestUserData = null;
      _selectedIndex = 4;
    });
    // 로그아웃 후 LoginPage로 이동
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

  Future<Map<String, dynamic>?> _fetchUserProfile(String uid) async {
    try {
      final doc = await FirebaseFirestore.instance.collection('users').doc(uid).get();
      if (doc.exists) return doc.data();
    } catch (e) {
      print('유저 데이터 로드 실패: $e');
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    final List<Widget> pages = [
      CameraPage(themeColor: _themeColor, onPhotoTaken: _loadImages),
      CollectionPage(
        themeColor: _themeColor,
        images: _images,
        previewColumns: _previewColumns,
        onPreviewSetting: () => setState(() {}),
        onImageDeleted: _loadImages,
      ),
      SearchPage(themeColor: _themeColor),
      GamePage(themeColor: _themeColor),
      (user == null && _guestUserData == null)
          ? const LoginPage()
          : (user != null)
          ? FutureBuilder<Map<String, dynamic>?>(
        future: _fetchUserProfile(user.uid),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final userData = snapshot.data;
          final String userUid = userData?['uid'] ?? user.uid;
          final String createDate = userData?['joinDate'] ??
              (user.metadata.creationTime != null
                  ? "${user.metadata.creationTime!.year}년 ${user.metadata.creationTime!.month}월 ${user.metadata.creationTime!.day}일"
                  : '알 수 없음');
          final String email = user.email ?? '알 수 없음';
          final int insectCount = userData?['insectCount'] ?? 0;

          return UserSettingPage(
            email: email,
            userUid: userUid,
            createDate: createDate,
            themeColor: _themeColor,
            insectCount: insectCount,
            onLogout: _onLogout,
            userData: userData,
            refreshUserData: () async => setState(() {}),
          );
        },
      )
          : UserSettingPage(
        email: _guestUserData!['email'],
        userUid: _guestUserData!['uid'],
        createDate: _guestUserData!['joinDate'],
        themeColor: _themeColor,
        insectCount: _guestUserData!['insectCount'],
        onLogout: _onLogout,
        userData: _guestUserData,
        refreshUserData: _loadGuestDataIfNeeded,
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
