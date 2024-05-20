import 'package:flutter/material.dart';
import 'package:flutter_naver_login/flutter_naver_login.dart';
import 'package:kakao_flutter_sdk/kakao_flutter_sdk.dart';
import 'Login_main.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  runApp(const LogoutApp());
}

class LogoutApp extends StatelessWidget {
  const LogoutApp ({Key? key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: LogoutWidget(),
    );
  }
}

class LogoutWidget extends StatelessWidget {
  const LogoutWidget({Key? key});

  Future<void> _naverLogout(BuildContext context) async {
    try {
      await FlutterNaverLogin.logOut();
      await _clearSharedPreferences(); // SharedPreferences에서 인증 정보 삭제
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => LoginApp()),
      );
    } catch (error) {
      print('로그아웃 실패, $error');
    }
  }

  Future<void> _googleLogout(BuildContext context) async {
    await FirebaseAuth.instance.signOut();
    await _clearSharedPreferences(); // SharedPreferences에서 인증 정보 삭제
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => LoginApp()),
    );
  }

  Future<void> _kakaoLogout(BuildContext context) async {
    try {
      await UserApi.instance.logout();
      print('로그아웃 성공, SDK에서 토큰 삭제');
      await _clearSharedPreferences(); // SharedPreferences에서 인증 정보 삭제
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => LoginApp()),
      );
    } catch (error) {
      print('로그아웃 실패, SDK에서 토큰 삭제 $error');
    }
  }

  // SharedPreferences에서 인증 정보 삭제하는 함수
  Future<void> _clearSharedPreferences() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear(); // SharedPreferences에서 모든 데이터 삭제
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ElevatedButton(
              onPressed: () => _naverLogout(context),
              child: Text("네이버 로그아웃"),
            ),
            ElevatedButton(
              onPressed: () => _googleLogout(context),
              child: Text("구글 로그아웃"),
            ),
            ElevatedButton(
              onPressed: () => _kakaoLogout(context),
              child: Text("카카오 로그아웃"),
            )
          ],
        ),
      ),
    );
  }
}
