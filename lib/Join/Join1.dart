import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:mailer/mailer.dart';
import 'package:mailer/smtp_server.dart';

class JoinEx2 extends StatefulWidget {
  const JoinEx2({Key? key}); // super.key -> Key? key로 수정

  @override
  _JoinState createState() => _JoinState();
}

class _JoinState extends State<JoinEx2> {

  final FirebaseFirestore _fs = FirebaseFirestore.instance;
  final TextEditingController _name = TextEditingController();
  final TextEditingController _id = TextEditingController();
  final TextEditingController _pwd = TextEditingController();
  final TextEditingController _pwd1 = TextEditingController();
  final TextEditingController _email = TextEditingController();
  final TextEditingController _phone = TextEditingController();

  late String randomCode = _generateRandomCode();

  void _register() async {
    if (_pwd.text != _pwd1.text) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('패스워드 다르자너')),
      );
      return;
    }

    var checkId = await _fs.collection('USERLIST')
        .where('id', isEqualTo: _id.text)
        .where('pwd', isEqualTo: _pwd.text).get();

    if (checkId.docs.isNotEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('이미 존재하는 아이디입니다.')),
      );
      return;
    }

    try {
      await _fs.collection('USERLIST').add({
        'name': _name.text,
        'id': _id.text,
        'pwd': _pwd.text,
        'email': _email.text,
        'phone': _phone.text,
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('가입되었음!!')),
      );
      _name.clear();
      _id.clear();
      _pwd.clear();
      _pwd1.clear();
      _email.clear();
      _phone.clear();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    }
  }

  final String serverUrl = 'http://10.0.2.2:4000/send-sms';


  void sendSMS() async {

    Map<String, String> data = {
      'to': _phone.text,  // 전달받은 전화번호 사용
      'from': '01046548947', // 고정
      'text': '인증 코드: $_generateRandomCode()' // 인증에 사용할 경우 난수 6자리
    };
    try {
      final response = await http.post(
        Uri.parse(serverUrl),
        headers: <String, String>{
          'Content-Type': 'application/json; charset=UTF-8',
        },
        body: jsonEncode(data),
      );

      print('Response status: ${response.statusCode}');
      print('Response body: ${response.body}');
    } catch (e) {
      print('Error sending request: $e');
    }
  }

  String _generateRandomCode() {
    const chars = '0123456789';
    final random = Random();
    return String.fromCharCodes(Iterable.generate(
        6, (_) => chars.codeUnitAt(random.nextInt(chars.length))));
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(title: Text("회원가입")),
        body: SingleChildScrollView(
          child: Center(
            child: Padding(
              padding: EdgeInsets.all(20.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  TextField(
                    controller: _id,
                    decoration: InputDecoration(
                      labelText: "아이디",
                      border: OutlineInputBorder(),
                    ),
                  ),
                  SizedBox(height: 20),
                  TextField(
                    controller: _name,
                    decoration: InputDecoration(
                      labelText: "이름",
                      border: OutlineInputBorder(),
                    ),
                  ),
                  SizedBox(height: 20),
                  TextField(
                    controller: _pwd,
                    obscureText: true,
                    decoration: InputDecoration(
                      labelText: "비밀번호",
                      border: OutlineInputBorder(),
                    ),
                  ),
                  SizedBox(height: 20),
                  TextField(
                    controller: _pwd1,
                    obscureText: true,
                    decoration: InputDecoration(
                      labelText: "비밀번호확인",
                      border: OutlineInputBorder(),
                    ),
                  ),
                  SizedBox(height: 20),
                  TextField(
                    controller: _email,
                    decoration: InputDecoration(
                      labelText: "이메일",
                      border: OutlineInputBorder(),
                    ),
                  ),
                  SizedBox(height: 20),
                  TextField(
                    controller: _phone,
                    decoration: InputDecoration(
                      labelText: "저나버노",
                      border: OutlineInputBorder(),
                    ),
                  ),
                  SizedBox(height: 20),
                  Row(
                    children: [
                      ElevatedButton(
                        onPressed: sendSMS,
                        child: Text('인증'),
                      ),
                      SizedBox(width: 20), // 추가할 텍스트 위젯
                    ],
                  ),
                  SizedBox(height: 20),
                  ElevatedButton(
                    onPressed: _register,
                    child: Text("사용자 가입!"),
                  ),
                  SizedBox(height: 20),
                ],
              ),
            ),
          ),
        ),
      ),
    );

  }
}
