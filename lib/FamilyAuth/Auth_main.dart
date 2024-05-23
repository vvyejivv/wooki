import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:wooki/login/Logout.dart';


void main() async {
  WidgetsFlutterBinding.ensureInitialized(); // Flutter 앱이 시작될 때 Firebase 초기화를 위해 필요합니다.
  await Firebase.initializeApp(); // Firebase 초기화
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
  String? email;

  @override
  void initState() {
    super.initState();
    // 사용자가 로그인되어 있는지 확인하고 현재 사용자의 이메일을 가져와서 필드에 설정합니다.
    // User? user = FirebaseAuth.instance.currentUser;
    // print(user);
    // if (user != null) {
    //   _myEmailController.text = user.email ?? '';
    // }
    _loadEmail();
  }

  Future<void> _loadEmail() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _myEmailController.text = prefs.getString('email') ?? '';
    });
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
                '상대 이메일',
                style: TextStyle(
                  fontFamily: 'Pretendard-Regular',
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              TextField(
                decoration: InputDecoration(
                  hintText: '상대방의 이메일을 입력하세요',
                  border: OutlineInputBorder(),
                ),
              ),
              SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  ElevatedButton(
                    onPressed: () {
                      // 인증 버튼 클릭 시 동작
                    },
                    child: Text('인증'),
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
