import 'dart:io';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:path_provider/path_provider.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:path/path.dart' as path;

import 'pages/camera_page.dart';
import 'pages/collection_page.dart';
import 'pages/search_page.dart';
import 'pages/game_page.dart';
import 'pages/login_page.dart';
import 'pages/user_setting_page.dart';
import 'theme/game_theme.dart';
import 'firebase/firebase_options.dart';
import 'storage/login_storage.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  final guestInfo = await readLoginInfo(guest: true);
  final userInfo = await readLoginInfo(guest: false);

  bool isGuest = guestInfo.isNotEmpty;
  bool isLoggedIn = userInfo.isNotEmpty;

  runApp(MyApp(
    isGuest: isGuest,
    isLoggedIn: isLoggedIn,
    guestInfo: guestInfo,
    userInfo: userInfo,
  ));
}

class MyApp extends StatelessWidget {
  final bool isGuest;
  final bool isLoggedIn;
  final Map<String, String> guestInfo;
  final Map<String, String> userInfo;

  const MyApp({
    super.key,
    required this.isGuest,
    required this.isLoggedIn,
    required this.guestInfo,
    required this.userInfo,
  });

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: '곤충 도감 앱',
      theme: ThemeData.dark(),
      debugShowCheckedModeBanner: false,
      home: isGuest
          ? MainNavigation(isGuest: true, selectedIndex: 4, loginInfo: guestInfo)
          : isLoggedIn
          ? MainNavigation(isGuest: false, selectedIndex: 4, loginInfo: userInfo)
          : const LoginPage(),
    );
  }
}

class MainNavigation extends StatefulWidget {
  final int selectedIndex;
  final bool isGuest;
  final Map<String, String>? loginInfo;

  const MainNavigation({
    super.key,
    this.selectedIndex = 0,
    this.isGuest = false,
    this.loginInfo,
  });

  @override
  State<MainNavigation> createState() => _MainNavigationState();
}

class _MainNavigationState extends State<MainNavigation> {
  late int _selectedIndex;
  late bool _isGuest;
  late Map<String, String> _loginInfo;
  Color _themeColor = Colors.deepPurple;
  List<File> _images = [];
  int _previewColumns = 2;
  Map<String, dynamic>? _userData;

  @override
  void initState() {
    super.initState();
    _selectedIndex = widget.selectedIndex;
    _isGuest = widget.isGuest;
    _loginInfo = widget.loginInfo ?? {};
    _loadImages();
    _loadThemeColor();
    _loadUserData();
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

  Future<void> _saveThemeColor(Color color) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('themeColor', color.value);
    setState(() {
      _themeColor = color;
    });
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

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  void _showPreviewSettingSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      builder: (_) => Container(
        padding: const EdgeInsets.all(16),
        child: Wrap(
          children: List.generate(6, (index) => index + 1).map((num) {
            return ElevatedButton(
              onPressed: () {
                setState(() {
                  _previewColumns = num;
                });
                Navigator.pop(context);
              },
              child: Text('$num개 보기'),
            );
          }).toList(),
        ),
      ),
    );
  }

  /// 🔥 Firestore에서 유저 정보 불러오기
  Future<void> _loadUserData() async {
    if (_isGuest) return;
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      final doc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
      if (doc.exists) {
        setState(() {
          _userData = doc.data();
        });
      }
    }
  }

  // 로그아웃
  void _onLogout() async {
    if (_isGuest) {
      // 게스트 로그아웃: txt를 남기고 그냥 로그인 페이지로 이동
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => const LoginPage()),
            (route) => false,
      );
    } else {
      // 회원 로그아웃: user_login.txt 삭제
      await clearLoginInfo(guest: false);
      await FirebaseAuth.instance.signOut();
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => const LoginPage()),
            (route) => false,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    Widget settingPage;
    if (_loginInfo.isEmpty) {
      settingPage = const Center(child: CircularProgressIndicator());
    } else {
      settingPage = UserSettingPage(
        email: _loginInfo['email'] ?? '알 수 없음',
        userUid: _loginInfo['uid'] ?? '알 수 없음',
        createDate: _loginInfo['loginDate'] ?? '알 수 없음',
        themeColor: _themeColor,
        insectCount: 0,
        onLogout: _onLogout,
        userData: _loginInfo,
        refreshUserData: () {},
      );
    }

    final pages = [
      CameraPage(themeColor: _themeColor, onPhotoTaken: _loadImages),
      CollectionPage(
        themeColor: _themeColor,
        images: _images,
        previewColumns: _previewColumns,
        onPreviewSetting: () => _showPreviewSettingSheet(context),
        onImageDeleted: _loadImages,
      ),
      SearchPage(themeColor: _themeColor),
      GamePage(themeColor: _themeColor),
      settingPage,
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
