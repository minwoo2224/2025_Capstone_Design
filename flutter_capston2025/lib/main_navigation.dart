import 'dart:io';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:path_provider/path_provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:path/path.dart' as path;

import 'package:flutter_capston2025/pages/camera_page.dart';
import 'package:flutter_capston2025/pages/collection_page.dart';
import 'package:flutter_capston2025/pages/search_page.dart';
import '../storage/login_storage.dart';
import 'package:flutter_capston2025/pages/login_page.dart';
import 'package:flutter_capston2025/pages/user_setting_page.dart'; // UserSettingPage 임포트 (실제 유저 설정 화면)
import 'package:flutter_capston2025/pages/game_page.dart';
import '../utils/load_all_cards.dart';

class MainNavigation extends StatefulWidget {
  final int selectedIndex;
  final bool isGuest;
  final Map<String, dynamic>? loginInfo; // loginInfo를 외부에서 받도록 추가

  const MainNavigation({
    super.key,
    this.selectedIndex = 0,
    this.isGuest = false,
    this.loginInfo, // 생성자에도 추가
  });

  @override
  State<MainNavigation> createState() => _MainNavigationState();
}

class _MainNavigationState extends State<MainNavigation> {
  late int _selectedIndex;
  late bool _isGuest;
  late Map<String, dynamic> _loginInfo; // Map<String, dynamic>으로 유지
  Color _themeColor = Colors.deepPurple;
  int _insectCount = 0; // ⭐ 초기값 할당: LateInitializationError 방지

  List<File> _images = []; // CollectionPage에서 사용될 이미지 목록
  int _previewColumns = 2; // CollectionPage에서 사용될 미리보기 열 개수

  @override
  void initState() {
    super.initState();
    _selectedIndex = widget.selectedIndex;
    _isGuest = widget.isGuest;
    _loginInfo = widget.loginInfo ?? {}; // 위젯으로부터 받은 loginInfo로 초기화

    _loadAllUserData(); // 로컬 및 Firebase 데이터 로딩
    _loadImages(); // 기존 이미지 로딩
    _loadThemeColor(); // 기존 테마 색상 로딩
  }

  // 모든 사용자 관련 데이터를 로딩하는 함수 (로컬 및 Firebase)
  Future<void> _loadAllUserData() async {
    Map<String, dynamic> info; // Map<String, dynamic>으로 유지
    if (_isGuest) {
      info = await readLoginInfo(guest: true);
      print('DEBUG (MainNavigation): Guest info from storage: $info');
      print('DEBUG (MainNavigation): Type of joinDate in guest info: ${info['joinDate']?.runtimeType}');
    } else {
      info = await readLoginInfo(guest: false);
      print('DEBUG (MainNavigation): User info from storage: $info');
      print('DEBUG (MainNavigation): Type of joinDate in user info: ${info['joinDate']?.runtimeType}');

      // Firebase에서 최신 사용자 데이터(insectCount, joinDate, userNumber 포함)를 불러옵니다.
      if (info.containsKey('uid')) {
        try {
          final userDoc = await FirebaseFirestore.instance.collection('users').doc(info['uid']).get();
          if (userDoc.exists && userDoc.data() != null) {
            print('DEBUG (MainNavigation): Firestore data before merge: ${userDoc.data()}');
            // Firestore에서 불러온 데이터를 _loginInfo에 병합 (Firestore 데이터가 우선)
            userDoc.data()!.forEach((key, value) {
              info[key] = value; // value를 그대로 사용
            });
            // Firebase에서 Timestamp로 저장된 경우, 이를 String으로 변환하여 저장
            // Firestore에 이미 ISO 8601 String으로 저장된 경우, 이 조건은 통과하지 않습니다.
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
      // _insectCount는 int 타입이므로 안전하게 파싱
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

  Future<void> _onLogout() async {
    if (_isGuest) {
      await clearLoginInfo(guest: true);
    } else {
      await clearLoginInfo(guest: false);
      await FirebaseAuth.instance.signOut(); // Firebase 로그아웃 추가
    }
    if (!mounted) return;
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => const LoginPage()),
          (route) => false,
    );
  }

  void _onItemTapped(int index) async {
    if (index == 3) { // 게임 탭
      final allCards = await loadAllCards(); // JSON에서 카드 로드
      if (context.mounted) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => GamePage(
              userUid: _loginInfo['uid']?.toString() ?? 'guest_uid', // 실제 userUid 전달
              playerCards: allCards, // 모든 카드 전달 (필요에 따라 사용자 소유 카드만 전달)
              opponentCards: [], // 상대 카드 (게임 로직에 따라 구현)
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

  // CollectionPage에서 이미지 삭제 후 호출될 콜백
  void _onImageDeleted() {
    _loadImages(); // 이미지 목록 새로고침
    _loadAllUserData(); // 곤충 카운트 등 사용자 데이터도 새로고침
  }

  // CameraPage에서 사진 촬영 후 호출될 콜백
  void _onPhotoTaken() {
    _loadImages(); // 이미지 목록 새로고침
    _loadAllUserData(); // 곤충 카운트 등 사용자 데이터도 새로고침
  }

  // CollectionPage의 미리보기 설정 시 호출될 콜백
  void _onPreviewSetting() {
    _showPreviewSettingSheet(context);
  }

  @override
  Widget build(BuildContext context) {
    // _loginInfo가 아직 로딩 중이거나 필수 필드가 없으면 로딩 표시
    // 이제 _insectCount는 초기화되어 있으므로 이 조건에서 제외합니다.
    if (_loginInfo.isEmpty || (_loginInfo['joinDate'] == null && !_isGuest)) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    // createDate를 UserSettingPage에 전달하기 전에 String으로 가공
    String createDateToPass;
    dynamic joinDateValue = _loginInfo['joinDate'];

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
      // joinDate도 없고, loginDate도 없는 경우
      createDateToPass = _loginInfo['loginDate']?.toString().split('T').first ?? '알 수 없음';
      print('DEBUG (MainNavigation build): joinDateValue is unknown. createDateToPass: $createDateToPass');
    }
    print('DEBUG (MainNavigation build): Final createDateToPass: $createDateToPass');


    final List<Widget> pages = [
      CameraPage(themeColor: _themeColor, onPhotoTaken: _onPhotoTaken),
      CollectionPage(
        themeColor: _themeColor,
        images: _images,
        previewColumns: _previewColumns,
        onPreviewSetting: _onPreviewSetting,
        onImageDeleted: _onImageDeleted,
      ),
      SearchPage(themeColor: _themeColor),
      const SizedBox(), // 게임 탭은 _onItemTapped에서 별도로 처리하므로 여기서는 빈 위젯
      UserSettingPage(
        email: _loginInfo['email']?.toString() ?? '알 수 없음', // dynamic에서 String으로 변환
        userUid: _loginInfo['uid']?.toString() ?? '알 수 없음', // dynamic에서 String으로 변환
        createDate: createDateToPass, // 이미 String으로 가공된 값 전달
        insectCount: _insectCount,
        themeColor: _themeColor,
        onLogout: _onLogout,
        userData: _loginInfo, // Map<String, dynamic> 그대로 전달
        refreshUserData: _loadAllUserData, // 사용자 데이터 새로고침 함수 전달
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