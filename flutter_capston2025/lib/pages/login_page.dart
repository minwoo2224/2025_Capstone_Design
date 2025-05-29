import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../main_navigation.dart';
import '../storage/login_storage.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});
  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  final FirebaseAuth auth = FirebaseAuth.instance;
  final FirebaseFirestore firestore = FirebaseFirestore.instance;

  bool isLogin = true;
  String message = '';
  bool isSuccess = false;

  Future<void> handleAuth() async {
    final email = emailController.text.trim();
    final password = passwordController.text.trim();

    if (email.isEmpty || password.isEmpty) {
      setState(() {
        message = '이메일과 비밀번호를 입력해주세요.';
        isSuccess = false;
      });
      return;
    }

    try {
      UserCredential credential;

      if (isLogin) {
        // --- 로그인 로직 ---
        credential = await auth.signInWithEmailAndPassword(
          email: email,
          password: password,
        );

        if (!credential.user!.emailVerified) {
          await auth.signOut();
          setState(() {
            message = '이메일 인증을 완료해주세요.';
            isSuccess = false;
          });
          return;
        }

        // 로그인 성공 시 Cloud Firestore에서 사용자 정보 불러오기
        final userUid = credential.user!.uid;
        final userDocRef = firestore.collection('users').doc(userUid);
        final userDoc = await userDocRef.get();

        Map<String, String> userDataForNavigation = {};

        if (userDoc.exists && userDoc.data() != null) {
          // 문서가 존재하면 정보를 불러와 사용
          print('로그인 사용자 정보 불러오기: ${userDoc.data()}');
          userDoc.data()!.forEach((key, value) {
            userDataForNavigation[key] = value.toString();
          });
          // 필수 필드가 없는 경우 기본값 부여 (견고한 앱을 위해 중요)
          userDataForNavigation['email'] ??= credential.user!.email ?? '';
          userDataForNavigation['uid'] ??= userUid;
          userDataForNavigation['joinDate'] ??= DateTime.now().toIso8601String();
          userDataForNavigation['insectCount'] ??= '0';
          userDataForNavigation['userNumber'] ??= '000000';
        } else {
          // 사용자는 로그인했지만 Firestore 문서가 없는 경우
          print('경고: Firestore에 사용자 문서가 없습니다. 새로 생성합니다.');
          final newUserNumber = await getAndIncrementUserNumber(); // userNumber 발급
          await saveNewUserToFirestore(credential.user!, newUserNumber: newUserNumber);
          userDataForNavigation = {
            'email': credential.user!.email ?? '',
            'uid': credential.user!.uid,
            'loginDate': DateTime.now().toIso8601String(), // 로컬 로그인 날짜 (FireStore와 다를 수 있음)
            'insectCount': '0', // 초기값
            'userNumber': newUserNumber, // 발급된 userNumber
            'joinDate': DateTime.now().toIso8601String(), // Firestore에 저장될 joinDate
          };
        }

        // 회원 로그인 성공 시 user_login.txt 저장, guest_login.txt 삭제
        await saveLoginInfo({
          'email': credential.user!.email ?? '',
          'uid': credential.user!.uid,
          'loginDate': DateTime.now().toIso8601String(),
        }, guest: false);
        await clearLoginInfo(guest: true);

        if (!mounted) return;
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(
            builder: (_) => MainNavigation( // MainNavigation으로 이동
              isGuest: false,
              selectedIndex: 4,
              loginInfo: userDataForNavigation, // 불러온 Firestore 데이터 전달
            ),
          ),
              (route) => false,
        );
      } else {
        // --- 회원가입 로직 ---
        credential = await auth.createUserWithEmailAndPassword(
          email: email,
          password: password,
        );
        await credential.user!.sendEmailVerification();

        // 회원가입 성공 시 Cloud Firestore에서 userNumber 발급 후 사용자 정보 저장
        final newUserNumber = await getAndIncrementUserNumber();
        await saveNewUserToFirestore(credential.user!, newUserNumber: newUserNumber);

        // 로컬 저장소에 정보 저장
        await saveLoginInfo({
          'email': credential.user!.email ?? '',
          'uid': credential.user!.uid,
          'loginDate': DateTime.now().toIso8601String(),
        }, guest: false);
        await clearLoginInfo(guest: true);

        setState(() {
          message = '회원가입 성공! 이메일 인증을 완료해주세요.';
          isSuccess = true;
        });
      }
    } on FirebaseAuthException catch (e) {
      setState(() {
        message = getErrorMessage(e.code);
        isSuccess = false;
      });
    } catch (e) {
      setState(() {
        message = '예외 발생: $e';
        isSuccess = false;
      });
    }
  }

  // Firebase Firestore에서 userNumber를 가져오고 1 증가시키는 트랜잭션 함수
  Future<String> getAndIncrementUserNumber() async {
    final userNumberDocRef = firestore.collection('NewUserNumber').doc('Number');

    return await firestore.runTransaction<String>((transaction) async {
      final snapshot = await transaction.get(userNumberDocRef);

      String lastUserNumber = '000000'; // 기본값 설정 (문서가 없거나 필드가 없는 경우)
      if (snapshot.exists && snapshot.data() != null && snapshot.data()!.containsKey('Last')) {
        lastUserNumber = snapshot.data()!['Last'] as String;
      } else {
        // 문서가 아예 없으면 초기 문서 생성 (예: 처음 사용자 가입 시)
        transaction.set(userNumberDocRef, {'Last': '000000'}); // 초기값 설정
      }

      // 문자열 '000001'을 숫자로 변환하여 1 증가
      int currentNumber = int.parse(lastUserNumber);
      int nextNumber = currentNumber + 1;

      // 다시 6자리 문자열 형식으로 포맷팅 (예: 1 -> "000001", 123 -> "000123")
      String newUserNumber = nextNumber.toString().padLeft(6, '0');

      // Firestore의 'Last' 필드를 업데이트
      transaction.set(userNumberDocRef, {'Last': newUserNumber});

      return newUserNumber;
    }).catchError((error) {
      print("userNumber 발급 트랜잭션 실패: $error");
      // 실패 시 기본값 또는 오류 처리 (예: 재시도, 고유한 ID 생성 등)
      return 'ERROR_${DateTime.now().millisecondsSinceEpoch % 1000000}'.padLeft(6, '0');
    });
  }

  // Firebase Firestore에 새 사용자 정보를 저장하는 함수
  // 발급된 userNumber를 인자로 받도록 수정
  Future<void> saveNewUserToFirestore(User user, {required String newUserNumber}) async {
    final docRef = firestore.collection('users').doc(user.uid);

    await docRef.set({
      'email': user.email ?? '',
      'uid': user.uid,
      'joinDate': DateTime.now().toIso8601String(), // 현재 시간으로 설정
      'insectCount': 0, // 초기 값으로 0 설정
      'userNumber': newUserNumber, // 발급받은 userNumber 사용
    });
    print('Firestore에 새 사용자 정보 저장: ${user.uid}, userNumber: $newUserNumber');
  }

  Future<void> handleGuestLogin() async {
    await saveLoginInfo({
      'email': 'guest@example.com',
      'uid': 'guest_uid',
      'loginDate': DateTime.now().toIso8601String(),
    }, guest: true);
    await clearLoginInfo(guest: false);

    if (!mounted) return;
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(
        builder: (_) => MainNavigation( // MainNavigation으로 이동
          isGuest: true,
          selectedIndex: 4,
          loginInfo: { // 게스트 정보도 loginInfo로 전달
            'email': 'guest@example.com',
            'uid': 'guest_uid',
            'loginDate': DateTime.now().toIso8601String(),
            'insectCount': '0',
            'userNumber': 'GUEST0', // 게스트용 userNumber
            'joinDate': DateTime.now().toIso8601String(),
          },
        ),
      ),
          (route) => false,
    );
  }

  String getErrorMessage(String code) {
    switch (code) {
      case 'invalid-email':
        return '이메일 형식이 올바르지 않습니다.';
      case 'user-not-found':
        return '존재하지 않는 사용자입니다.';
      case 'wrong-password':
        return '비밀번호가 틀렸습니다.';
      case 'invalid-credential':
        return '로그인 정보가 유효하지 않습니다.';
      case 'email-already-in-use':
        return '이미 등록된 이메일입니다.';
      case 'weak-password':
        return '비밀번호는 6자 이상이어야 합니다.';
      case 'too-many-requests':
        return '요청이 너무 많습니다. 잠시 후 다시 시도해주세요.';
      default:
        return '오류 발생: $code';
    }
  }

  @override
  void dispose() {
    emailController.dispose();
    passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: Text(isLogin ? '로그인' : '회원가입'),
        backgroundColor: Colors.indigo,
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: ListView(
          children: [
            const SizedBox(height: 30),
            Icon(Icons.account_circle, size: 100, color: Colors.white70),
            const SizedBox(height: 30),
            TextField(
              controller: emailController,
              style: const TextStyle(color: Colors.white),
              decoration: const InputDecoration(
                labelText: '이메일',
                labelStyle: TextStyle(color: Colors.white70),
                enabledBorder: UnderlineInputBorder(
                  borderSide: BorderSide(color: Colors.white30),
                ),
                focusedBorder: UnderlineInputBorder(
                  borderSide: BorderSide(color: Colors.white),
                ),
              ),
              keyboardType: TextInputType.emailAddress,
            ),
            const SizedBox(height: 16),
            TextField(
              controller: passwordController,
              obscureText: true,
              style: const TextStyle(color: Colors.white),
              decoration: const InputDecoration(
                labelText: '비밀번호',
                labelStyle: TextStyle(color: Colors.white70),
                enabledBorder: UnderlineInputBorder(
                  borderSide: BorderSide(color: Colors.white30),
                ),
                focusedBorder: UnderlineInputBorder(
                  borderSide: BorderSide(color: Colors.white),
                ),
              ),
            ),
            const SizedBox(height: 30),
            ElevatedButton(
              onPressed: handleAuth,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.deepPurple,
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
              child: Text(isLogin ? '로그인' : '회원가입', style: const TextStyle(fontSize: 16)),
            ),
            const SizedBox(height: 10),
            TextButton(
              onPressed: () => setState(() => isLogin = !isLogin),
              child: Text(
                isLogin ? '계정이 없으신가요? 회원가입' : '계정이 있으신가요? 로그인',
                style: const TextStyle(color: Colors.white60),
              ),
            ),
            const SizedBox(height: 10),
            Divider(color: Colors.white24),
            const SizedBox(height: 10),
            TextButton(
              onPressed: handleGuestLogin,
              child: const Text(
                '게스트로 계속하기',
                style: TextStyle(color: Colors.grey, fontSize: 15),
              ),
            ),
            const SizedBox(height: 20),
            if (message.isNotEmpty)
              Text(
                message,
                style: TextStyle(
                  color: isSuccess ? Colors.greenAccent : Colors.redAccent,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
          ],
        ),
      ),
    );
  }
}