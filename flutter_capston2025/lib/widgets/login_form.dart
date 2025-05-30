import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../main_navigation.dart';
import '../storage/login_storage.dart';

class LoginForm extends StatefulWidget {
  const LoginForm({super.key});

  @override
  State<LoginForm> createState() => _LoginFormState();
}

class _LoginFormState extends State<LoginForm> {
  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  final auth = FirebaseAuth.instance;
  final firestore = FirebaseFirestore.instance;

  bool isLogin = true;
  String message = '';
  bool isSuccess = false;

  @override
  void dispose() {
    emailController.dispose();
    passwordController.dispose();
    super.dispose();
  }

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
        credential = await auth.signInWithEmailAndPassword(email: email, password: password);

        if (!credential.user!.emailVerified) {
          await auth.signOut();
          setState(() {
            message = '이메일 인증을 완료해주세요.';
            isSuccess = false;
          });
          return;
        }

        final uid = credential.user!.uid;
        final doc = await firestore.collection('users').doc(uid).get();
        Map<String, String> userData = {};

        if (doc.exists && doc.data() != null) {
          doc.data()!.forEach((key, value) {
            userData[key] = value.toString();
          });
          userData['email'] ??= credential.user!.email ?? '';
          userData['uid'] ??= uid;
          userData['joinDate'] ??= DateTime.now().toIso8601String();
          userData['insectCount'] ??= '0';
          userData['userNumber'] ??= '000000';
          userData['nickname'] ??= '이름없는벌레';
        } else {
          final newNumber = await getAndIncrementUserNumber();
          await saveNewUserToFirestore(credential.user!, newUserNumber: newNumber);
          userData = {
            'email': credential.user!.email ?? '',
            'uid': uid,
            'loginDate': DateTime.now().toIso8601String(),
            'insectCount': '0',
            'userNumber': newNumber,
            'joinDate': DateTime.now().toIso8601String(),
            'nickname': '이름없는벌레',
          };
        }

        await saveLoginInfo(userData, guest: false);
        await clearLoginInfo(guest: true);

        if (!mounted) return;
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(
            builder: (_) => MainNavigation(isGuest: false, selectedIndex: 4, loginInfo: userData),
          ),
              (route) => false,
        );
      } else {
        credential = await auth.createUserWithEmailAndPassword(email: email, password: password);
        await credential.user!.sendEmailVerification();
        final newNumber = await getAndIncrementUserNumber();
        await saveNewUserToFirestore(credential.user!, newUserNumber: newNumber);
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

  Future<void> resetPassword() async {
    final email = emailController.text.trim();
    if (email.isEmpty) {
      setState(() {
        message = '비밀번호 재설정을 위해 이메일을 입력해주세요.';
        isSuccess = false;
      });
      return;
    }

    try {
      await auth.sendPasswordResetEmail(email: email);
      setState(() {
        message = '비밀번호 재설정 이메일을 전송했습니다.';
        isSuccess = true;
      });
    } catch (e) {
      setState(() {
        message = '비밀번호 재설정 실패: $e';
        isSuccess = false;
      });
    }
  }

  Future<String> getAndIncrementUserNumber() async {
    final docRef = firestore.collection('NewUserNumber').doc('Number');

    return await firestore.runTransaction<String>((transaction) async {
      final snapshot = await transaction.get(docRef);
      String last = snapshot.data()?['Last'] ?? '000000';
      int next = int.parse(last) + 1;
      String newNumber = next.toString().padLeft(6, '0');
      transaction.set(docRef, {'Last': newNumber});
      return newNumber;
    });
  }

  Future<void> saveNewUserToFirestore(User user, {required String newUserNumber}) async {
    await firestore.collection('users').doc(user.uid).set({
      'email': user.email ?? '',
      'uid': user.uid,
      'joinDate': DateTime.now().toIso8601String(),
      'insectCount': 0,
      'userNumber': newUserNumber,
      'nickname': '이름없는벌레',
    });
  }

  Future<void> handleGuestLogin() async {
    await saveLoginInfo({
      'email': 'guest@example.com',
      'uid': 'guest_uid',
      'loginDate': DateTime.now().toIso8601String(),
      'insectCount': '0',
      'userNumber': 'GUEST0',
      'joinDate': DateTime.now().toIso8601String(),
      'nickname': '게스트',
    }, guest: true);
    await clearLoginInfo(guest: false);

    if (!mounted) return;
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(
        builder: (_) => MainNavigation(
          isGuest: true,
          selectedIndex: 4,
          loginInfo: {
            'email': 'guest@example.com',
            'uid': 'guest_uid',
            'loginDate': DateTime.now().toIso8601String(),
            'insectCount': '0',
            'userNumber': 'GUEST0',
            'joinDate': DateTime.now().toIso8601String(),
            'nickname': '게스트',
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
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: ListView(
        shrinkWrap: true,
        children: [
          const SizedBox(height: 30),
          const Icon(Icons.account_circle, size: 100, color: Colors.white70),
          const SizedBox(height: 30),
          TextField(
            controller: emailController,
            style: const TextStyle(color: Colors.white),
            decoration: const InputDecoration(
              labelText: '이메일',
              labelStyle: TextStyle(color: Colors.white70),
              enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: Colors.white30)),
              focusedBorder: UnderlineInputBorder(borderSide: BorderSide(color: Colors.white)),
            ),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: passwordController,
            obscureText: true,
            style: const TextStyle(color: Colors.white),
            decoration: const InputDecoration(
              labelText: '비밀번호',
              labelStyle: TextStyle(color: Colors.white70),
              enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: Colors.white30)),
              focusedBorder: UnderlineInputBorder(borderSide: BorderSide(color: Colors.white)),
            ),
          ),
          Align(
            alignment: Alignment.centerRight,
            child: TextButton(
              onPressed: resetPassword,
              child: const Text('비밀번호를 잊으셨나요?', style: TextStyle(color: Colors.white60)),
            ),
          ),
          ElevatedButton(
            onPressed: handleAuth,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.deepPurple,
              padding: const EdgeInsets.symmetric(vertical: 14),
            ),
            child: Text(isLogin ? '로그인' : '회원가입', style: const TextStyle(fontSize: 16)),
          ),
          TextButton(
            onPressed: () => setState(() => isLogin = !isLogin),
            child: Text(
              isLogin ? '계정이 없으신가요? 회원가입' : '계정이 있으신가요? 로그인',
              style: const TextStyle(color: Colors.white60),
            ),
          ),
          Divider(color: Colors.white24),
          TextButton(
            onPressed: handleGuestLogin,
            child: const Text('게스트로 계속하기', style: TextStyle(color: Colors.grey)),
          ),
          if (message.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 12),
              child: Text(
                message,
                style: TextStyle(
                  color: isSuccess ? Colors.greenAccent : Colors.redAccent,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
            ),
        ],
      ),
    );
  }
}
