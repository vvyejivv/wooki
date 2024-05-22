import 'dart:convert';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:math';
import 'find_id2.dart';
import 'package:provider/provider.dart';
import 'search_id.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized(); // 필수는 아니지만 권장됩니다.
  await Firebase.initializeApp(); // Firebase 초기화
  runApp(MyApp());
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
  bool _isVerified = false; // 인증 상태를 관리하는 변수

  late SearchId searchId; // SearchId 인스턴스를 저장할 변수

  @override
  void initState() {
    super.initState();
  }

  // 6자리 난수 생성 함수
  int generateSixDigitRandomNumber() {
    Random random = Random();
    int min = 100000; // 6자리 최소값
    int max = 999999; // 6자리 최대값
    return min + random.nextInt(max - min + 1);
  }

  void _showErrorDialog(BuildContext context) {
    showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: Text("오류"),
            content: Text("인증번호가 틀렸습니다."),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop();
                },
                child: Text("확인"),
              ),
            ],
          );
        }
    );
  }

  void _showEmptyDialog(BuildContext context) {
    showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: Container(),
            content: Text("폰번호를 입력하세요."),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop();
                },
                child: Text("확인"),
              ),
            ],
          );
        }
    );
  }

  void _showDialog(BuildContext context, int randomCode){
    final TextEditingController codeController = TextEditingController();
    showDialog(
        context : context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: Text("인증번호"),
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
                        _isVerified = true; // 인증 완료 시 true로 설정
                      });
                      Navigator.of(context).pop(); // 인증번호가 맞을 때 다이얼로그 닫기
                    } else {
                      _showErrorDialog(context); // 인증번호가 틀릴 때 오류 다이얼로그 표시
                    }
                  },
                  child: Text("확인")
              ),
              TextButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                  child: Text("취소")
              )
            ],
          );
        }
    );
  }

 // 나중에 서버로 변경
  void sendSMS(BuildContext context, String phone) async {
    int randomCode = generateSixDigitRandomNumber(); // 6자리 난수 생성
    Map<String, String> data = {
      'to': phone, // 사용자가 입력하는 번호
      'from': '01046548947', // 고정
      'text': '인증코드: $randomCode' // 인증에 사용할 경우 난수 6자ㅏ리
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
    // final searchId = Provider.of<SearchId>(context);
    searchId = Provider.of<SearchId>(context, listen: false); // SearchId 인스턴스 초기화
    return Scaffold(
      appBar: AppBar(
        title: Text('아이디 찾기'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Text(
              '아이디 찾기',
              style: TextStyle(fontSize: 24.0, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 20.0),
            TextField(
              controller: phoneController,
              decoration: InputDecoration(
                labelText: '폰번호 입력',
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.phone,
              enabled: !_isVerified,
            ),
            SizedBox(height: 20.0),
            ElevatedButton(
              onPressed: () async {
                // 아이디 찾기 로직 추가
                // SearchId searchId = SearchId();
                if (!_isVerified) {
                  String phone = phoneController.text;
                  if (phone.isEmpty){
                    _showEmptyDialog(context);
                  } else {
                    await searchId.search(phone);
                    if (searchId.isSearch) {
                      print('입력한 폰번호: $phone');
                      sendSMS(context, phone); // SMS 전송 후 다이얼로그 표시
                    } else {
                      print('가입한 번호가 없습니다.');
                    }
                  }
                } else {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => FindID2()),
                  );
                }
              },
              child: Text(_isVerified ? '다음' : '인증번호 전송'),
            ),
          ],
        ),
      ),
    );
  }
}
