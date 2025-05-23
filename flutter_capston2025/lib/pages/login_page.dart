import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'settings_page.dart';


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

  Future<void> handleAuth() async {
    final email = emailController.text.trim();
    final password = passwordController.text.trim();

    if (email.isEmpty || password.isEmpty) {
      setState(() => message = '이메일과 비밀번호를 입력해주세요.');
      return;
    }

    try {
      UserCredential credential;

      if (isLogin) {
        // 로그인
        credential = await auth.signInWithEmailAndPassword(
          email: email,
          password: password,
        );

        if (!credential.user!.emailVerified) {
          await auth.signOut();
          setState(() => message = '이메일 인증을 완료해주세요.');
          return;
        }

        setState(() => message = '로그인 성공! ${credential.user!.email}');
        Navigator.pop(context); // 또는 홈 화면 이동
      } else {
        // 회원가입
        credential = await auth.createUserWithEmailAndPassword(
          email: email,
          password: password,
        );

        await credential.user!.sendEmailVerification();
        setState(() => message = '회원가입 성공! 이메일 인증을 완료해주세요.');
      }
    } on FirebaseAuthException catch (e) {
      setState(() => message = getErrorMessage(e.code));
    } catch (e) {
      setState(() => message = '예외 발생: $e');
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
        title: Text(
          isLogin ? '로그인' : '회원가입',
          style: const TextStyle(color: Colors.white),
        ),
        backgroundColor: Colors.indigo,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            TextField(
              controller: emailController,
              style: const TextStyle(color: Colors.white),
              decoration: const InputDecoration(
                labelText: '이메일',
                labelStyle: TextStyle(color: Colors.white),
                enabledBorder: UnderlineInputBorder(
                  borderSide: BorderSide(color: Colors.white70),
                ),
                focusedBorder: UnderlineInputBorder(
                  borderSide: BorderSide(color: Colors.white),
                ),
              ),
              keyboardType: TextInputType.emailAddress,
            ),
            TextField(
              controller: passwordController,
              obscureText: true,
              style: const TextStyle(color: Colors.white),
              decoration: const InputDecoration(
                labelText: '비밀번호',
                labelStyle: TextStyle(color: Colors.white),
                enabledBorder: UnderlineInputBorder(
                  borderSide: BorderSide(color: Colors.white70),
                ),
                focusedBorder: UnderlineInputBorder(
                  borderSide: BorderSide(color: Colors.white),
                ),
              ),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: handleAuth,
              style: ElevatedButton.styleFrom(backgroundColor: Colors.purple),
              child: Text(isLogin ? '로그인' : '회원가입'),
            ),
            TextButton(
              onPressed: () => setState(() => isLogin = !isLogin),
              child: Text(
                isLogin ? '계정이 없으신가요? 회원가입' : '계정이 있으신가요? 로그인',
                style: const TextStyle(color: Colors.white),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              message,
              style: const TextStyle(color: Colors.redAccent),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
