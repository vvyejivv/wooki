import 'dart:async';
import 'dart:convert';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:http/http.dart' as http;
import 'package:mailer/mailer.dart';
import 'package:mailer/smtp_server.dart';
import 'package:mailer/smtp_server/gmail.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  runApp(FamilyAuth());
}

class FamilyAuth extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(home: EmailAuth());
  }
}

class EmailAuth extends StatefulWidget {
  @override
  State<EmailAuth> createState() => _EmailAuthState();
}

class _EmailAuthState extends State<EmailAuth> {
  final TextEditingController _myEmailController = TextEditingController();
  final TextEditingController _otherEmailController = TextEditingController();
  final TextEditingController _verificationCodeController = TextEditingController();
  final String serverUrl = 'http://10.0.2.2:4000/send-sms';
  String? selectedEmail;
  List<String> invitations = [];
  String? _verificationCode;
  bool _isVerificationFieldVisible = false;
  String? _myDocId;
  String? _otherDocId;

  @override
  void initState() {
    super.initState();
    _loadEmail();
  }

  Future<void> _loadEmail() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _myEmailController.text = prefs.getString('email') ?? '';
      _fetchInvitations();
    });
  }

  Future<void> _fetchInvitations() async {
    String email = _myEmailController.text;
    QuerySnapshot userDocs = await FirebaseFirestore.instance
        .collection('USERLIST')
        .where('email', isEqualTo: email)
        .limit(1)
        .get();

    if (userDocs.docs.isNotEmpty) {
      DocumentSnapshot userDoc = userDocs.docs.first;
      setState(() {
        _myDocId = userDoc.id;
        Map<String, dynamic> data = userDoc.data() as Map<String, dynamic>;
        if (data.containsKey('invitations')) {
          invitations = List<String>.from(data['invitations']);
        }
      });
    }
  }

  Future<void> _inviteMember(String email) async {
    String myEmail = _myEmailController.text;
    DocumentReference userDocRef = FirebaseFirestore.instance.collection('USERLIST').doc(_myDocId);

    await FirebaseFirestore.instance.runTransaction((transaction) async {
      DocumentSnapshot userDoc = await transaction.get(userDocRef);
      if (userDoc.exists) {
        List<dynamic> invitations = userDoc.get('invitations') ?? [];
        if (!invitations.contains(email)) {
          invitations.add(email);
          transaction.update(userDocRef, {'invitations': invitations});
        }
      } else {
        transaction.set(userDocRef, {
          'email': myEmail,
          'invitations': [email]
        });
      }
    });

    _fetchInvitations();
  }

  Future<void> _checkFamilyMember(String input) async {
    QuerySnapshot userDocs;

    if (input.contains('@')) {
      // 입력된 값이 이메일인 경우
      userDocs = await FirebaseFirestore.instance
          .collection('USERLIST')
          .where('email', isEqualTo: input)
          .get();
    } else {
      // 입력된 값이 전화번호인 경우
      userDocs = await FirebaseFirestore.instance
          .collection('USERLIST')
          .where('phone', isEqualTo: input)
          .get();
    }

    if (userDocs.docs.isNotEmpty) {
      // 이메일 또는 전화번호가 존재하는 경우, 인증번호 발송 및 인증 프로세스 시작
      setState(() {
        _otherDocId = userDocs.docs.first.id; // 상대방 문서 ID 저장
      });
      if (input.contains('@')) {
        // 이메일일 경우
        _generateAndSendEmailCode(input);
      } else {
        // 전화번호일 경우
        _generateAndSendVerificationCode(input);
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('입력하신 정보가 존재하지 않습니다.')),
      );
    }
  }

  Future<void> sendSMS(String phone, String code) async {
    Map<String, String> data = {
      'to': phone, // 사용자가 입력하는 번호
      'from': '01046548947', // 고정
      'text': '인증코드: $code' // 인증에 사용할 경우 난수 6자리
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

  void _generateAndSendVerificationCode(String input) {
    setState(() {
      _isVerificationFieldVisible = true;
      _verificationCode = _generateVerificationCode();
      sendSMS(input, _verificationCode!);
      print('Generated verification code: $_verificationCode');
    });
  }

  void _generateAndSendEmailCode(String email) {
    setState(() {
      _isVerificationFieldVisible = true;
      _verificationCode = _generateVerificationCode();
      _sendEmail(email, _verificationCode!);
      print('Generated verification code: $_verificationCode');
    });
  }

  String _generateVerificationCode() {
    Random random = Random();
    return (100000 + random.nextInt(900000)).toString(); // 6자리 난수 생성
  }

  Future<void> _sendEmail(String recipient, String code) async {
    // Gmail SMTP 서버 설정
    final smtpServer = gmail('tjoeun231204@gmail.com', 'mwct isyk lbfz qojz');

    // 메일 내용
    final message = Message()
      ..from = Address('your_email@gmail.com', 'Wooki')
      ..recipients.add(recipient)
      ..subject = '인증 코드'
      ..text = '인증 코드: $code';

    try {
      final sendReport = await send(message, smtpServer);
      print('Message sent: ' + sendReport.toString());
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('이메일이 성공적으로 전송되었습니다.'),
        ),
      );
    } catch (e) {
      print('Error: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('이메일을 전송하는 동안 오류가 발생했습니다.'),
        ),
      );
    }
  }

  void _verifyCode() async {
    if (_verificationCodeController.text == _verificationCode) {
      await _addFamilyMember(_myDocId, _otherDocId);
      await _updateFamilyLinked(_myDocId, _otherDocId);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('인증번호가 틀렸습니다.')),
      );
    }
  }

  Future<void> _addFamilyMember(String? myDocId, String? otherDocId) async {
    if (myDocId != null && otherDocId != null) {
      DocumentSnapshot myUserDocSnapshot = await FirebaseFirestore.instance.collection('USERLIST').doc(myDocId).get();
      DocumentSnapshot otherUserDocSnapshot = await FirebaseFirestore.instance.collection('USERLIST').doc(otherDocId).get();

      if (myUserDocSnapshot.exists && otherUserDocSnapshot.exists) {
        var myUserEmail = myUserDocSnapshot['email'];
        var myUserName = myUserDocSnapshot['name'];

        var otherUserEmail = otherUserDocSnapshot['email'];
        var otherUserName = otherUserDocSnapshot['name'];

        // 현재 사용자의 FAMILY 서브컬렉션에 상대방 정보 추가
        await FirebaseFirestore.instance.collection('USERLIST').doc(myDocId).collection('FAMILY').add({
          'familyEmail': otherUserEmail,
          'familyName': otherUserName,
          'addedAt': FieldValue.serverTimestamp(), // 추가된 시간
        });

        // 상대방의 FAMILY 서브컬렉션에 현재 사용자 정보 추가
        await FirebaseFirestore.instance.collection('USERLIST').doc(otherDocId).collection('FAMILY').add({
          'familyEmail': myUserEmail,
          'familyName': myUserName,
          'addedAt': FieldValue.serverTimestamp(), // 추가된 시간
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('가족 구성원이 추가되었습니다.')),
        );

        setState(() {
          _isVerificationFieldVisible = false;
          _verificationCodeController.clear();
          _otherEmailController.clear();
        });
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('가족 구성원을 추가할 수 없습니다.')),
        );
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('가족 구성원을 추가할 수 없습니다.')),
      );
    }
  }

  Future<void> _updateFamilyLinked(String? myDocId, String? otherDocId) async {
    if (myDocId != null && otherDocId != null) {
      await FirebaseFirestore.instance.collection('USERLIST').doc(myDocId).update({'familyLinked': true});
      await FirebaseFirestore.instance.collection('USERLIST').doc(otherDocId).update({'familyLinked': true});
    }
  }

  void _showInvitationListDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('초대 받은 목록'),
          content: Container(
            width: double.maxFinite,
            child: StatefulBuilder(
              builder: (BuildContext context, StateSetter setState) {
                return ListView(
                  shrinkWrap: true,
                  children: invitations.map((invitation) {
                    return RadioListTile<String>(
                      title: Text(invitation),
                      value: invitation,
                      groupValue: selectedEmail,
                      onChanged: (value) {
                        setState(() {
                          selectedEmail = value;
                        });
                      },
                    );
                  }).toList(),
                );
              },
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                setState(() {
                  _otherEmailController.text = selectedEmail ?? '';
                });
                Navigator.of(context).pop();
              },
              child: Text('확인'),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: Text('닫기'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Color(0xFFFFFDEF),
      ),
      backgroundColor: Color(0xFFFFFDEF),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '내 이메일',
                style: TextStyle(
                  fontFamily: 'Pretendard-Regular',
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _myEmailController,
                      decoration: InputDecoration(
                        border: OutlineInputBorder(),
                      ),
                    ),
                  ),
                  ElevatedButton(
                    onPressed: () {
                      // 공유하기 버튼 클릭 시 동작
                    },
                    child: Text('공유하기'),
                  ),
                ],
              ),
              SizedBox(height: 20),
              Text(
                '상대 이메일 or 전화번호',
                style: TextStyle(
                  fontFamily: 'Pretendard-Regular',
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              TextField(
                controller: _otherEmailController,
                decoration: InputDecoration(
                  hintText: '상대방의 이메일 또는 전화번호를 입력하세요',
                  border: OutlineInputBorder(),
                ),
              ),
              SizedBox(height: 20),
              ElevatedButton(
                onPressed: () {
                  _checkFamilyMember(_otherEmailController.text);
                },
                child: Text('발송'),
              ),
              if (_isVerificationFieldVisible) ...[
                TextField(
                  controller: _verificationCodeController,
                  decoration: InputDecoration(
                    hintText: '인증번호를 입력하세요',
                    border: OutlineInputBorder(),
                  ),
                ),
                SizedBox(height: 20),
                ElevatedButton(
                  onPressed: _verifyCode,
                  child: Text('확인'),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}