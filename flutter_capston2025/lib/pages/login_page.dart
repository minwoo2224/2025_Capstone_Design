import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_capston2025/pigeon/auth_bridge.dart';
import '../main_navigation.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  final FirebaseAuth auth = FirebaseAuth.instance;

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

        await _sendUserToNative(credential.user!);

        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('uid', credential.user!.uid);

        setState(() {
          message = '로그인 성공! ${credential.user!.email}';
          isSuccess = true;
        });

        // ★★★ 여기가 중요 ★★★
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) => const MainNavigation(selectedIndex: 4),
          ),
        );
      } else {
        credential = await auth.createUserWithEmailAndPassword(
          email: email,
          password: password,
        );

        await credential.user!.sendEmailVerification();
        await _sendUserToNative(credential.user!);

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

  Future<void> _sendUserToNative(User user) async {
    final details = PigeonUserDetails()
      ..uid = user.uid
      ..email = user.email
      ..displayName = user.displayName;

    try {
      final api = AuthBridge();
      await api.sendUserDetails(details);
    } catch (e) {
      print('Native 전달 실패: $e');
    }
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
                enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: Colors.white30)),
                focusedBorder: UnderlineInputBorder(borderSide: BorderSide(color: Colors.white)),
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
                enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: Colors.white30)),
                focusedBorder: UnderlineInputBorder(borderSide: BorderSide(color: Colors.white)),
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
