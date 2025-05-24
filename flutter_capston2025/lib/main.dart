import 'dart:io';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:path_provider/path_provider.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart'; // 🔥 Firestore import
import 'package:path/path.dart' as path;

import 'pages/camera_page.dart';
import 'pages/collection_page.dart';
import 'pages/search_page.dart';
import 'pages/game_page.dart';
import 'pages/login_page.dart';
import 'pages/user_setting_page.dart';
import 'theme/game_theme.dart';
import 'firebase/firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  final prefs = await SharedPreferences.getInstance();
  final email = prefs.getString('email');
  final isGuest = email == 'guest@example.com';
  final isLoggedIn = isGuest || FirebaseAuth.instance.currentUser != null;

  runApp(MyApp(isLoggedIn: isLoggedIn));
}

class MyApp extends StatelessWidget {
  final bool isLoggedIn;
  const MyApp({super.key, required this.isLoggedIn});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: '곤충 도감 앱',
      theme: buildGameTheme(),
      debugShowCheckedModeBanner: false,
      home: isLoggedIn
          ? const MainNavigation(selectedIndex: 4)
          : const LoginPage(),
    );
  }
}

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

  // Firestore 유저 데이터용 변수
  Map<String, dynamic>? _userData;

  @override
  void initState() {
    super.initState();
    _selectedIndex = widget.selectedIndex;
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

  // 로그아웃 시 LoginPage로 이동
  void _onLogout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('uid');
    await FirebaseAuth.instance.signOut();
    if (!mounted) return;
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(
        builder: (_) => const LoginPage(),
      ),
          (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

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
      UserSettingPage(
        email: user?.email ?? '알 수 없음',
        userUid: user?.uid ?? '알 수 없음',
        createDate: _userData?['joinDate'] ??
            (user?.metadata.creationTime != null
                ? "${user!.metadata.creationTime!.year}년 ${user.metadata.creationTime!.month}월 ${user.metadata.creationTime!.day}일"
                : '알 수 없음'),
        insectCount: _userData?['insectCount'] ?? 0,
        themeColor: _themeColor,
        onLogout: _onLogout,
        userData: _userData,
        refreshUserData: _loadUserData,
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
