import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:wooki/login/Logout.dart';

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
  String? selectedEmail;
  List<String> invitations = [];

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
    DocumentSnapshot userDoc = await FirebaseFirestore.instance.collection('USERLIST').doc(email).get();

    if (userDoc.exists) {
      Map<String, dynamic> data = userDoc.data() as Map<String, dynamic>;
      if (data.containsKey('invitations')) {
        setState(() {
          invitations = List<String>.from(data['invitations']);
        });
      }
    }
  }

  Future<void> _inviteMember(String email) async {
    String myEmail = _myEmailController.text;
    DocumentReference userDocRef = FirebaseFirestore.instance.collection('USERLIST').doc(myEmail);

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
      // 이메일 또는 전화번호가 존재하는 경우, 초대 목록에 추가
      await _inviteMember(input);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('초대가 완료되었습니다.')),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('입력하신 정보가 존재하지 않습니다.')),
      );
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
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  ElevatedButton(
                    onPressed: () {
                      _checkFamilyMember(_otherEmailController.text);
                    },
                    child: Text('확인'),
                  ),
                ],
              ),
              SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  ElevatedButton(
                    onPressed: _showInvitationListDialog,
                    child: Text('초대 받은 목록'),
                  ),
                ],
              ),
              SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }
}
