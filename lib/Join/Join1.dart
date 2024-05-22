import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';

class JoinEx2 extends StatefulWidget {
  const JoinEx2({Key? key});

  @override
  _JoinState createState() => _JoinState();
}

class _JoinState extends State<JoinEx2> {
  final FirebaseFirestore _fs = FirebaseFirestore.instance;
  final TextEditingController _name = TextEditingController();
  final TextEditingController _pwd = TextEditingController();
  final TextEditingController _pwd1 = TextEditingController();
  final TextEditingController _email = TextEditingController();
  final TextEditingController _phone = TextEditingController();
  final TextEditingController _todayDateController = TextEditingController();

  final TextEditingController _verificationCodeController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _setTodayDate();
  }

  void _setTodayDate() {
    final DateTime dateTime = DateTime.now();
    String formattedDate = DateFormat('yyyy-MM-dd HH:mm:ss').format(dateTime);
    _todayDateController.text = formattedDate;
  }

  String? _generatedCode;
  bool _isSendingSMS = false;
  bool _isVerificationSent = false;
  bool _isVerified = false;
  String _snackBarMessage = '';

  void _register() async {
    if (!_isVerified) {
      _showSnackBar('먼저 인증을 완료하세요.');
      return;
    }

    if (_pwd.text != _pwd1.text) {
      _showSnackBar('패스워드가 다릅니다.');
      return;
    }

    if (_pwd.text.isEmpty || _pwd.text != _pwd1.text) {
      _showSnackBar('비밀번호를 확인하세요.');
      return;
    }

    if (!_isValidEmail(_email.text)) {
      _showSnackBar('올바른 이메일 주소를 입력하세요.');
      return;
    }

    try {
      await _fs.collection('USERLIST').add({
        'name': _name.text,
        'pwd': _pwd.text,
        'email': _email.text,
        'phone': _phone.text,
        'todayDate': FieldValue.serverTimestamp(), // 서버 타임스탬프 사용
      });

      _showSnackBar('가입되었음!!');
      _name.clear();
      _pwd.clear();
      _pwd1.clear();
      _email.clear();
      _phone.clear();
      _verificationCodeController.clear();
    } catch (e) {
      _showSnackBar('Error: $e');
    }
  }

  bool _isValidEmail(String email) {
    String emailRegex = r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$';
    return RegExp(emailRegex).hasMatch(email);
  }

  final String serverUrl = 'http://10.0.2.2:4000/send-sms';

  void sendSMS() async {
    if (_isSendingSMS) return;

    setState(() {
      _isSendingSMS = true;
    });

    String code = _generateRandomCode();
    setState(() {
      _generatedCode = code;
      _isVerificationSent = true;
    });

    Map<String, String> data = {
      'to': _phone.text,
      'from': '01046548947',
      'text': '인증 코드: $code'
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
      setState(() {
        _isSendingSMS = false;
      });
    }
  }

  void verifyCode() {
    String enteredCode = _verificationCodeController.text.trim();
    print("enteredCode ==> $enteredCode");
    print("_generatedCode ==> $_generatedCode");
    if (enteredCode.isEmpty) {
      _showSnackBar('인증 코드를 입력하세요.');
      return;
    }

    if (enteredCode == _generatedCode) {
      setState(() {
        _isVerified = true;
      });
      _showSnackBar('인증 완료되었습니다.');
    } else {
      _showSnackBar('인증 코드가 다릅니다. 다시 시도해주세요.');
    }
  }

  String _generateRandomCode() {
    const chars = '0123456789';
    final random = Random();
    return String.fromCharCodes(Iterable.generate(
        6, (_) => chars.codeUnitAt(random.nextInt(chars.length))));
  }

  void _showSnackBar(String message) {
    print(message);
    if (message.isNotEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message)),
      );
    }
  }

  void _checkEmail() async {
    if (_email.text.isEmpty) {
      _showSnackBar('이메일을 입력하세요.');
      return;
    }

    try {
      var checkEmail = await _fs
          .collection('USERLIST')
          .where('email', isEqualTo: _email.text)
          .get();

      if (checkEmail.docs.isNotEmpty) {
        _showSnackBar('이미 존재하는 이메일입니다.');
      } else {
        _showSnackBar('사용 가능한 이메일입니다.');
      }
    } catch (e) {
      _showSnackBar('이메일 확인 중 오류가 발생했습니다: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        backgroundColor: Color.fromARGB(255, 255, 253, 239),
        appBar: AppBar(
          title: Text("회원가입"),
          backgroundColor: Color.fromARGB(255, 255, 253, 239),
        ),
        body: Container(
          child: SingleChildScrollView(
            child: Center(
              child: Padding(
                padding: EdgeInsets.all(20.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.start,
                  children: [
                    TextField(
                      controller: _email,
                      decoration: InputDecoration(
                        labelText: "이메일",
                        hintText: "이메일을 입력하세요",
                        border: OutlineInputBorder(),
                      ),
                    ),
                    SizedBox(height: 20),
                    Row(
                      children: [
                        ElevatedButton(
                          onPressed: _checkEmail,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Color.fromRGBO(
                                255, 219, 28, 1), // RGB 값으로 배경색 지정
                          ),
                          child: Text(
                            '중복 확인',
                            style: TextStyle(
                                color: Colors.black), // 텍스트 색상을 검정색으로 변경
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 20), // 여백 추가
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
                        labelText: "비밀번호 확인",
                        border: OutlineInputBorder(),
                      ),
                    ),
                    SizedBox(height: 20),
                    TextField(
                      controller: _phone,
                      decoration: InputDecoration(
                        labelText: "전화번호",
                        border: OutlineInputBorder(),
                      ),
                    ),
                    SizedBox(height: 20),
                    Row(
                      children: [
                        ElevatedButton(
                          onPressed: sendSMS,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Color.fromRGBO(
                                255, 219, 28, 1), // RGB 값으로 배경색 지정
                          ),
                          child: Text(
                            '인증',
                            style: TextStyle(
                                color: Colors.black), // 텍스트 색상을 검정색으로 변경
                          ),
                        ),
                      ],
                    ),
                    if (_isVerificationSent) ...[
                      SizedBox(height: 20),
                      TextField(
                        controller: _verificationCodeController,
                        decoration: InputDecoration(
                          labelText: "인증 코드 입력",
                          border: OutlineInputBorder(),
                        ),
                      ),
                      SizedBox(height: 20),
                      ElevatedButton(
                        onPressed: verifyCode,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Color.fromRGBO(
                              255, 219, 28, 1), // RGB 값으로 배경색 지정
                        ),
                        child: Text(
                          '인증 완료',
                          style: TextStyle(
                              color: Colors.black), // 텍스트 색상을 검정색으로 변경
                        ),
                      ),
                    ],
                    SizedBox(height: 20),
                    ElevatedButton(
                      onPressed: _register,
                      style: ElevatedButton.styleFrom(
                        backgroundColor:
                        Color.fromRGBO(255, 219, 28, 1), // RGB 값으로 배경색 지정
                      ),
                      child: Text(
                        '사용자 가입!',
                        style:
                        TextStyle(color: Colors.black), // 텍스트 색상을 검정색으로 변경
                      ),
                    ),
                    SizedBox(height: 20),
                    if (_snackBarMessage.isNotEmpty)
                      SnackBar(
                        content: Text(_snackBarMessage),
                      ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
