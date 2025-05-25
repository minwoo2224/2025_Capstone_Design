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
import 'pages/login_page.dart';
import 'pages/user_setting_page.dart';
import 'pages/card_selection_page.dart';
import 'models/insect_card.dart';
import 'theme/game_theme.dart';
import 'firebase/firebase_options.dart';
import 'storage/login_storage.dart';
import 'socket/socket_service.dart';
import 'utils/load_all_cards.dart'; // 새로 만든 모든 카드 로드 함수

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  SocketService.connect();

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

  @override
  void initState() {
    super.initState();
    _selectedIndex = widget.selectedIndex;
    _isGuest = widget.isGuest;
    _loginInfo = widget.loginInfo ?? {};
    _loadImages();
    _loadThemeColor();
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

  void _onItemTapped(int index) async {
    if (index == 3) {
      // 게임 탭
      final allCards = await loadAllCards(); // JSON에서 카드 로드
      if (context.mounted) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => CardSelectionPage(allCards: allCards),
          ),
        );
      }
      return;
    }

    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    final settingPage = _loginInfo.isEmpty
        ? const Center(child: CircularProgressIndicator())
        : UserSettingPage(
      email: _loginInfo['email'] ?? '알 수 없음',
      userUid: _loginInfo['uid'] ?? '알 수 없음',
      createDate: _loginInfo['loginDate'] ?? '알 수 없음',
      themeColor: _themeColor,
      insectCount: 0,
      onLogout: () async {
        if (_isGuest) {
          Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const LoginPage()));
        } else {
          await clearLoginInfo(guest: false);
          await FirebaseAuth.instance.signOut();
          Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const LoginPage()));
        }
      },
      userData: _loginInfo,
      refreshUserData: () {},
    );

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
      const SizedBox(), // 게임 페이지는 따로 열림
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
}
