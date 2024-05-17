import 'package:flutter/material.dart';
import 'Login_kakao.dart';
import 'package:kakao_flutter_sdk_user/kakao_flutter_sdk_user.dart';
import 'dart:io';
import 'package:flutter/services.dart';
import 'package:flutter_naver_login/flutter_naver_login.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:wooki/firebase_options.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:wooki/main.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(home: MyWidget());
  }
}

class MyWidget extends StatefulWidget {
  const MyWidget({super.key});

  @override
  State<MyWidget> createState() => _MyWidgetState();
}

class _MyWidgetState extends State<MyWidget> {
  final FirebaseFirestore _fs = FirebaseFirestore.instance;
  void _naverLogin() async{
    var email = '';
    try{
      final NaverLoginResult res = await FlutterNaverLogin.logIn();
      print('accessToken = ${res.accessToken}');
      print('id = ${res.account.id}');
      print('email = ${res.account.email}');
      print('name = ${res.account.name}');
      email = res.account.email;
      if(email == ''){
        return;
      }else{
        _userCheck(email);
      }

    } catch(error){
      print(error);
    }
  }

  void _userCheck(email) async{
    final userDocs = await _fs.collection('USERLIST')
        .where('id', isEqualTo: email).get();
    print(userDocs);
    if(userDocs.docs.isNotEmpty){
      Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => MainPage())
      );
    }else{
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('오류')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Color(0xFFFFFDEF),
      ),
      body: Container(
        color: Color(0xFFFFFDEF),
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SizedBox(height: 16),
            ElevatedButton(
              onPressed: _naverLogin,
              child: Text('네이버 로그인'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Color(0xFF03C75A),
                foregroundColor: Colors.white,
                minimumSize: Size(double.infinity, 50),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8), // 버튼의 모서리를 조절합니다.
                ),
              ),
            ),
            SizedBox(height: 16),
            ElevatedButton(
              onPressed: () {
                // Google login logic
              },
              child: Text('구글 로그인'),
              style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: Colors.black,
                  minimumSize: Size(double.infinity, 50),
                  side: BorderSide(color: Colors.grey),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(5))),
            ),
            SizedBox(height: 16),
            ElevatedButton(
              onPressed: () {
                // Apple login logic
              },
              child: Text('애플 로그인'),
              style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.black,
                  foregroundColor: Colors.white,
                  minimumSize: Size(double.infinity, 50),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(5))),
            ),
          ],
        ),
      ),
    );
  }
}


