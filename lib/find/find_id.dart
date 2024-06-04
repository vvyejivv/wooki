import 'dart:convert';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:math';
import 'find_id2.dart';
import 'package:provider/provider.dart';
import 'search_id.dart';
import 'package:wooki/login/Login_main.dart';
import 'package:wooki/Join/Join1.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => SearchId()),
      ],
      child: MyApp(),
    ),
  );
}


class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Find ID Page',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: FindIDPage(),
    );
  }
}

class FindIDPage extends StatefulWidget {
  @override
  State<FindIDPage> createState() => _FindIDPageState();
}

class _FindIDPageState extends State<FindIDPage> {
  final TextEditingController phoneController = TextEditingController();
  final String serverUrl = 'http://10.0.2.2:4000/send-sms';
  bool _isVerified = false;

  int generateSixDigitRandomNumber() {
    Random random = Random();
    int min = 100000;
    int max = 999999;
    return min + random.nextInt(max - min + 1);
  }

  void _showErrorDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: Color(0xFFFFFDEF),
          title: Text("오류"),
          content: Text(
              "인증번호가 틀렸습니다.",
            style: TextStyle(
              fontFamily: 'Pretendard-SemiBold',
              fontSize: 15,
              color: Color(0xFF3A281F),
              fontWeight: FontWeight.bold,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: Text("확인"),
            ),
          ],
        );
      },
    );
  }

  void _showEmptyDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: Color(0xFFFFFDEF),
          title: Container(),
          content: Text("폰번호를 입력하세요.",style: TextStyle(
            fontFamily: 'Pretendard-SemiBold',
            fontSize: 15,
            color: Color(0xFF3A281F),
            fontWeight: FontWeight.bold,
          ),),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: Text("확인"),
            ),
          ],
        );
      },
    );
  }

  void _showNoDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: Color(0xFFFFFDEF),
          title: Container(),
          content: Text("가입한 번호가 없습니다.",style: TextStyle(
            fontFamily: 'Pretendard-SemiBold',
            fontSize: 15,
            color: Color(0xFF3A281F),
            fontWeight: FontWeight.bold,
          ),),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: Text("확인"),
            ),
          ],
        );
      },
    );
  }

  void _showDialog(BuildContext context, int randomCode) {
    final TextEditingController codeController = TextEditingController();
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: Color(0xFFFFFDEF),
          title: Text("인증번호",style: TextStyle(
            fontFamily: 'Pretendard-SemiBold',
            fontSize: 15,
            color: Color(0xFF3A281F),
            fontWeight: FontWeight.bold,
          ),),
          content: TextField(
            controller: codeController,
            decoration: InputDecoration(
              labelText: '인증번호 입력',
              border: OutlineInputBorder(),
            ),
            keyboardType: TextInputType.number,
          ),
          actions: [
            TextButton(
              onPressed: () {
                String enteredCode = codeController.text;
                if (enteredCode == randomCode.toString()) {
                  setState(() {
                    _isVerified = true;
                  });
                  Navigator.of(context).pop();
                } else {
                  _showErrorDialog(context);
                }
              },
              child: Text("확인"),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: Text("취소"),
            )
          ],
        );
      },
    );
  }

  void sendSMS(BuildContext context, String phone) async {
    int randomCode = generateSixDigitRandomNumber();
    Map<String, String> data = {
      'to': phone,
      'from': '01046548947',
      'text': '인증코드: $randomCode'
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
    } finally {
      _showDialog(context, randomCode);
    }
  }

  @override
  Widget build(BuildContext context) {
    final searchId = Provider.of<SearchId>(context);
    return Scaffold(
      backgroundColor: Color(0xFFFFFDEF),
      appBar: AppBar(
        automaticallyImplyLeading: false,
        backgroundColor: Color(0xFFFFFDEF),
        title: Container(
          margin: EdgeInsets.only(top: 60, bottom: 50),
          child: Image.asset('assets/img/wooki_logo.png'),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Text(
              '서비스 이용을 위해 인증을 완료해주세요.',
              style: TextStyle(fontSize: 16.0, color: Colors.black),
            ),
            SizedBox(height: 20.0),
            TextField(
              controller: phoneController,
              decoration: InputDecoration(
                labelText: '폰번호를 입력해주세요.',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                filled: true,
                fillColor: Colors.white,
              ),
              keyboardType: TextInputType.phone,
              enabled: !_isVerified,
            ),
            SizedBox(height: 20.0),
            ElevatedButton(
              onPressed: () async {
                if (!_isVerified) {
                  String phone = phoneController.text;
                  if (phone.isEmpty) {
                    _showEmptyDialog(context);
                  } else {
                    await searchId.search(phone);
                    if (searchId.isSearch) {
                      print('입력한 폰번호: $phone');
                      sendSMS(context, phone);
                    } else {
                      _showNoDialog(context);
                    }
                  }
                } else {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => FindID2()),
                  );
                }
              },
              child: Text(
                  _isVerified ? '다음' : '인증번호 전송',
                  style: TextStyle(
                  fontFamily: 'Pretendard-SemiBold',
                  fontSize: 15,
                  color: Color(0xFF3A281F),
                  fontWeight: FontWeight.bold),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: Color(0xFFFFE458),
                foregroundColor: Color(0xFF3A281F),
                minimumSize: Size(double.infinity, 50),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(5),
                ),
              ),
            ),
            SizedBox(height: 10.0),
            ElevatedButton(
              onPressed: () {
                Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => LoginApp())
                );
              },
              child: Text(
                  '로그인',
                style: TextStyle(
                    fontFamily: 'Pretendard-SemiBold',
                    fontSize: 15,
                    color: Colors.white,
                    fontWeight: FontWeight.bold),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: Color(0xFF6D605A),
                minimumSize: Size(double.infinity, 50),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(5),
                ),
              ),
            ),
            SizedBox(height: 20.0),
            TextButton(
              onPressed: () {
                Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => JoinEx2())
                );
              },
              child: Text(
                '회원가입',
                style: TextStyle(color: Colors.black),
              ),
            ),
            SizedBox(height: 20.0),
          ],
        ),
      ),
    );
  }
}
