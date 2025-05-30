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
import 'pages/game_page.dart';
import 'firebase/firebase_options.dart';
import 'storage/login_storage.dart';
import 'utils/load_all_cards.dart';
import 'socket/socket_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // ✅ 소켓 초기화
  SocketService.connect();

  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

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
  final Map<String, dynamic> guestInfo;
  final Map<String, dynamic> userInfo;

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
  final Map<String, dynamic>? loginInfo;

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
  late Map<String, dynamic> _loginInfo;
  Color _themeColor = Colors.deepPurple;
  int _insectCount = 0;
  List<File> _images = [];
  int _previewColumns = 2;

  @override
  void initState() {
    super.initState();
    _selectedIndex = widget.selectedIndex;
    _isGuest = widget.isGuest;
    _loginInfo = widget.loginInfo ?? {};
    _loadAllUserData();
    _loadImages();
    _loadThemeColor();
  }

  Future<void> _loadAllUserData() async {
    Map<String, dynamic> info = _isGuest
        ? await readLoginInfo(guest: true)
        : await readLoginInfo(guest: false);

    if (!_isGuest && info.containsKey('uid')) {
      try {
        final userDoc = await FirebaseFirestore.instance.collection('users').doc(info['uid']).get();
        if (userDoc.exists && userDoc.data() != null) {
          userDoc.data()!.forEach((key, value) => info[key] = value);
          if (info['joinDate'] is Timestamp) {
            info['joinDate'] = (info['joinDate'] as Timestamp).toDate().toIso8601String();
          }

          final prefs = await SharedPreferences.getInstance();
          if (info.containsKey('nickname')) {
            prefs.setString('nickname', info['nickname'].toString());
          }
        }
      } catch (e) {
        print("Firestore 로딩 오류: $e");
      }
    }

    info['email'] ??= '알 수 없음';
    info['uid'] ??= '알 수 없음';
    info['joinDate'] ??= DateTime.now().toIso8601String();
    info['insectCount'] ??= 0;
    info['userNumber'] ??= '000000';
    info['nickname'] ??= _isGuest ? '게스트' : '이름없는벌레';

    setState(() {
      _loginInfo = info;
      _insectCount = (info['insectCount'] is int)
          ? info['insectCount']
          : int.tryParse(info['insectCount']?.toString() ?? '0') ?? 0;
    });
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
      final allCards = await loadAllCards();
      if (context.mounted) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => GamePage(
              userUid: _loginInfo['uid']?.toString() ?? 'guest_uid',
              playerCards: allCards,
              opponentCards: [],
              themeColor: _themeColor,
            ),
          ),
        );
      }
      return;
    }
    setState(() {
      _selectedIndex = index;
    });
  }

  Future<void> _onLogout() async {
    if (_isGuest) {
      await clearLoginInfo(guest: true);
    } else {
      await clearLoginInfo(guest: false);
      await FirebaseAuth.instance.signOut();
    }
    if (!mounted) return;
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => const LoginPage()),
          (route) => false,
    );
  }

  String formatJoinDate(dynamic joinDateValue) {
    if (joinDateValue is Timestamp) {
      return joinDateValue.toDate().toIso8601String().split('T').first;
    } else if (joinDateValue is String && joinDateValue.contains('T')) {
      return joinDateValue.split('T').first;
    } else if (joinDateValue is String) {
      return joinDateValue;
    } else {
      return _loginInfo['loginDate']?.toString().split('T').first ?? '알 수 없음';
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loginInfo.isEmpty && !_isGuest) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    final createDateToPass = formatJoinDate(_loginInfo['joinDate']);

    final pages = [
      CameraPage(themeColor: _themeColor, onPhotoTaken: () {
        _loadImages();
        _loadAllUserData();
      }),
      CollectionPage(
        themeColor: _themeColor,
        images: _images,
        previewColumns: _previewColumns,
        onPreviewSetting: () => _showPreviewSettingSheet(context),
        onImageDeleted: () {
          _loadImages();
          _loadAllUserData();
        },
      ),
      SearchPage(themeColor: _themeColor),
      const SizedBox(),
      UserSettingPage(
        email: _loginInfo['email']?.toString() ?? '알 수 없음',
        userUid: _loginInfo['uid']?.toString() ?? '알 수 없음',
        createDate: createDateToPass,
        insectCount: _insectCount,
        themeColor: _themeColor,
        onLogout: _onLogout,
        userData: _loginInfo,
        refreshUserData: _loadAllUserData,
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
          BottomNavigationBarItem(icon: Icon(Icons.bug_report), label: '곤충'),
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
          spacing: 10,
          runSpacing: 10,
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