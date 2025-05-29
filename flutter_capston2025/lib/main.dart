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
import 'storage/login_storage.dart'; // import login_storage.dart
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

  // Firebase에서 실제 사용자 데이터를 불러오는 로직 추가
  Map<String, dynamic> actualUserInfo = {}; // ⭐ Map<String, dynamic>으로 변경
  if (isLoggedIn && userInfo.containsKey('uid')) {
    try {
      final userUid = userInfo['uid']!.toString(); // dynamic 타입에서 String으로 변환
      final userDoc = await FirebaseFirestore.instance.collection('users').doc(userUid).get();
      if (userDoc.exists && userDoc.data() != null) {
        actualUserInfo = userDoc.data()!; // Firestore 데이터는 이미 Map<String, dynamic>
        // Firestore에서 Timestamp로 저장된 경우, 이를 String으로 변환하여 저장
        if (actualUserInfo['joinDate'] is Timestamp) {
          actualUserInfo['joinDate'] = (actualUserInfo['joinDate'] as Timestamp).toDate().toIso8601String();
        }
        // 필수 필드가 없는 경우 기본값 부여 (견고한 앱을 위해 중요)
        actualUserInfo['email'] ??= userInfo['email'] ?? '';
        actualUserInfo['uid'] ??= userUid;
        actualUserInfo['joinDate'] ??= DateTime.now().toIso8601String();
        actualUserInfo['insectCount'] ??= 0; // int 타입으로 유지
        actualUserInfo['userNumber'] ??= '000000';
      } else {
        // Firebase에 사용자 문서가 없는 경우, 로컬 정보만 사용하고 기본값 설정
        actualUserInfo = userInfo;
        actualUserInfo['email'] ??= userInfo['email'] ?? '';
        actualUserInfo['uid'] ??= userUid;
        actualUserInfo['joinDate'] ??= DateTime.now().toIso8601String();
        actualUserInfo['insectCount'] ??= 0; // int 타입으로 유지
        actualUserInfo['userNumber'] ??= '000000';
        print("경고: 로그인된 사용자이나 Firestore에 문서가 없습니다.");
      }
    } catch (e) {
      print("Firebase 사용자 정보 로드 중 오류 발생: $e");
      // 오류 발생 시 로컬 정보 사용하고 기본값 설정
      actualUserInfo = userInfo;
      actualUserInfo['email'] ??= userInfo['email'] ?? '';
      actualUserInfo['uid'] ??= userInfo['uid'] ?? '';
      actualUserInfo['joinDate'] ??= DateTime.now().toIso8601String();
      actualUserInfo['insectCount'] ??= 0; // int 타입으로 유지
      actualUserInfo['userNumber'] ??= '000000';
    }
  } else {
    // 로그인 안 되어있거나 UID 없는 경우에도 기본값 설정
    actualUserInfo = userInfo; // 로컬 userInfo가 Map<String, dynamic>이므로 그대로 사용
    actualUserInfo['email'] ??= '';
    actualUserInfo['uid'] ??= '';
    actualUserInfo['joinDate'] ??= DateTime.now().toIso8601String();
    actualUserInfo['insectCount'] ??= 0; // int 타입으로 유지
    actualUserInfo['userNumber'] ??= '000000';
  }

  runApp(MyApp(
    isGuest: isGuest,
    isLoggedIn: isLoggedIn,
    guestInfo: guestInfo, // readLoginInfo에서 Map<String, dynamic>을 반환하므로 OK
    userInfo: actualUserInfo, // Firebase에서 불러온 실제 사용자 정보 전달
  ));
}

class MyApp extends StatelessWidget {
  final bool isGuest;
  final bool isLoggedIn;
  final Map<String, dynamic> guestInfo; // ⭐ Map<String, dynamic>으로 변경
  final Map<String, dynamic> userInfo; // ⭐ Map<String, dynamic>으로 변경

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
          ? MainNavigation(isGuest: false, selectedIndex: 4, loginInfo: userInfo) // 실제 사용자 정보 전달
          : const LoginPage(),
    );
  }
}

class MainNavigation extends StatefulWidget {
  final int selectedIndex;
  final bool isGuest;
  final Map<String, dynamic>? loginInfo; // ⭐ Map<String, dynamic>으로 변경

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
  late Map<String, dynamic> _loginInfo; // ⭐ Map<String, dynamic>으로 변경
  Color _themeColor = Colors.deepPurple;
  int _insectCount = 0; // ⭐ 초기값 할당 및 int 타입으로 유지
  List<File> _images = [];
  int _previewColumns = 2;

  @override
  void initState() {
    super.initState();
    _selectedIndex = widget.selectedIndex;
    _isGuest = widget.isGuest;
    _loginInfo = widget.loginInfo ?? {}; // widget.loginInfo를 직접 사용
    _loadAllUserData(); // 데이터 로딩 함수 추가
    _loadImages();
    _loadThemeColor();
  }

  // ⭐ 새로 추가된 _loadAllUserData 함수 (main.dart의 로직과 유사)
  Future<void> _loadAllUserData() async {
    Map<String, dynamic> info;
    if (_isGuest) {
      info = await readLoginInfo(guest: true);
      print('DEBUG (MainNavigation): Guest info from storage: $info');
      print('DEBUG (MainNavigation): Type of joinDate in guest info: ${info['joinDate']?.runtimeType}');
    } else {
      info = await readLoginInfo(guest: false);
      print('DEBUG (MainNavigation): User info from storage: $info');
      print('DEBUG (MainNavigation): Type of joinDate in user info: ${info['joinDate']?.runtimeType}');

      if (info.containsKey('uid')) {
        try {
          final userDoc = await FirebaseFirestore.instance.collection('users').doc(info['uid'].toString()).get();
          if (userDoc.exists && userDoc.data() != null) {
            print('DEBUG (MainNavigation): Firestore data before merge: ${userDoc.data()}');
            // Firestore에서 불러온 데이터를 _loginInfo에 병합 (Firestore 데이터가 우선)
            userDoc.data()!.forEach((key, value) {
              info[key] = value; // value는 이미 dynamic
            });
            // Firebase에서 Timestamp로 저장된 경우, 이를 String으로 변환하여 저장
            if (info['joinDate'] is Timestamp) {
              info['joinDate'] = (info['joinDate'] as Timestamp).toDate().toIso8601String();
              print('DEBUG (MainNavigation): joinDate converted from Timestamp: ${info['joinDate']}');
            }
            print('DEBUG (MainNavigation): Info after Firestore merge: $info');
            print('DEBUG (MainNavigation): Type of joinDate after Firestore merge: ${info['joinDate']?.runtimeType}');

          } else {
            print("경고: 로그인된 사용자이나 Firestore에 문서가 없습니다.");
          }
        } catch (e) {
          print("Firestore에서 사용자 데이터 로드 중 오류 발생: $e");
        }
      }
    }

    // 로컬 info 맵의 필수 필드 보완 (Firebase에서 가져오지 못했거나 없는 경우)
    info['email'] ??= '알 수 없음';
    info['uid'] ??= '알 수 없음';
    info['joinDate'] ??= DateTime.now().toIso8601String(); // ISO 8601 String으로 저장
    info['insectCount'] ??= 0; // 숫자로 유지
    info['userNumber'] ??= '000000';
    print('DEBUG (MainNavigation): Info after default value assignment: $info');
    print('DEBUG (MainNavigation): Type of joinDate after default value assignment: ${info['joinDate']?.runtimeType}');

    setState(() {
      _loginInfo = info;
      print('DEBUG (MainNavigation): _loginInfo in setState: $_loginInfo');
      print('DEBUG (MainNavigation): Type of _loginInfo["joinDate"] in setState: ${_loginInfo['joinDate']?.runtimeType}');
      _insectCount = (_loginInfo['insectCount'] is int) ? _loginInfo['insectCount'] as int : int.tryParse(_loginInfo['insectCount']?.toString() ?? '0') ?? 0;
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

  // 사용자 데이터를 새로고침하는 함수 (Firestore에서 다시 불러오기)
  Future<void> _refreshUserData() async {
    if (!_isGuest && _loginInfo.containsKey('uid')) {
      try {
        final userUid = _loginInfo['uid']!.toString(); // dynamic에서 String으로 변환
        final userDoc = await FirebaseFirestore.instance.collection('users').doc(userUid).get();
        if (userDoc.exists && userDoc.data() != null) {
          setState(() {
            _loginInfo = userDoc.data()!; // Firestore 데이터는 Map<String, dynamic>
            // Timestamp 변환 로직도 다시 적용
            if (_loginInfo['joinDate'] is Timestamp) {
              _loginInfo['joinDate'] = (_loginInfo['joinDate'] as Timestamp).toDate().toIso8601String();
            }
          });
          print("사용자 데이터 새로고침 완료: $_loginInfo");
        }
      } catch (e) {
        print("사용자 데이터 새로고침 중 오류 발생: $e");
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // _loginInfo가 아직 로딩 중이거나 필수 필드가 없으면 로딩 표시
    if (_loginInfo.isEmpty && !_isGuest) { // 게스트는 로딩 필요 없음
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    // createDate를 UserSettingPage에 전달하기 전에 String으로 가공
    String createDateToPass;
    dynamic joinDateValue = _loginInfo['joinDate']; // dynamic 타입으로 받기

    print('DEBUG (MainNavigation build): joinDateValue from _loginInfo: $joinDateValue');
    print('DEBUG (MainNavigation build): Type of joinDateValue: ${joinDateValue?.runtimeType}');

    if (joinDateValue is Timestamp) {
      createDateToPass = joinDateValue.toDate().toIso8601String().split('T').first;
      print('DEBUG (MainNavigation build): joinDateValue is Timestamp. createDateToPass: $createDateToPass');
    } else if (joinDateValue is String && joinDateValue.contains('T')) {
      // "2025-05-23T13:08:25Z" 와 같은 ISO 8601 문자열 처리
      createDateToPass = joinDateValue.split('T').first;
      print('DEBUG (MainNavigation build): joinDateValue is ISO String. createDateToPass: $createDateToPass');
    } else if (joinDateValue is String) {
      // "2025-05-23" 와 같이 이미 날짜 문자열인 경우
      createDateToPass = joinDateValue;
      print('DEBUG (MainNavigation build): joinDateValue is simple String. createDateToPass: $createDateToPass');
    } else {
      // joinDate도 없고, loginDate도 없는 경우 (이전 로컬 저장소에서 loginDate를 사용했을 수 있음)
      createDateToPass = (_loginInfo['loginDate']?.toString().split('T').first) ?? '알 수 없음';
      print('DEBUG (MainNavigation build): joinDateValue is unknown. createDateToPass: $createDateToPass');
    }
    print('DEBUG (MainNavigation build): Final createDateToPass: $createDateToPass');


    final settingPage = UserSettingPage(
      email: _loginInfo['email']?.toString() ?? '알 수 없음', // dynamic에서 String으로 변환
      userUid: _loginInfo['uid']?.toString() ?? '알 수 없음', // dynamic에서 String으로 변환
      createDate: createDateToPass, // 가공된 날짜 전달
      themeColor: _themeColor,
      insectCount: _insectCount, // ⭐ _insectCount 사용
      onLogout: () async {
        if (_isGuest) {
          await clearLoginInfo(guest: true); // 게스트 로그인 정보 클리어
          Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const LoginPage()));
        } else {
          await clearLoginInfo(guest: false); // 일반 사용자 로그인 정보 클리어
          await FirebaseAuth.instance.signOut(); // Firebase 로그아웃
          Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const LoginPage()));
        }
      },
      userData: _loginInfo, // Map<String, dynamic> 그대로 전달
      refreshUserData: _refreshUserData, // 데이터 새로고침 함수 전달
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
          spacing: 10, // 버튼 간의 가로 간격
          runSpacing: 10, // 줄 간의 세로 간격
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