import 'package:flutter/material.dart';
import 'search_id.dart';
import 'package:provider/provider.dart';
import 'dart:convert';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:wooki/login/Login_main.dart';

void main() {
  runApp(FindID2());
}

class FindID2 extends StatelessWidget {
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
  final _formKey = GlobalKey<FormState>();

  Future<void> _updatePwd(String email, String pwd) async {
    FirebaseFirestore fs = FirebaseFirestore.instance;
    CollectionReference users = fs.collection("USERLIST");

    QuerySnapshot snap = await users.where('email', isEqualTo: email).get();
    for (QueryDocumentSnapshot doc in snap.docs) {
      await users.doc(doc.id).update({'pwd': pwd});
    }
  }

  bool isValidPassword(String password) {
    String passwordRegex = r'^(?=.*?[A-Z])(?=.*?[a-z])(?=.*?[0-9])(?=.*?[!@#\$&*~]).{8,}$';
    // 최소 8자 이상이어야 하며, 대문자, 소문자, 숫자, 특수문자 중에서 4종류가 모두 포함되어야
    return RegExp(passwordRegex).hasMatch(password);
  }

  void _showChangeDialog(BuildContext context, String email) {
    final TextEditingController pwdController = TextEditingController();
    final TextEditingController pwd2Controller = TextEditingController();
    final scaffoldContext = context;

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: Color(0xFFFFFDEF), // 모달창 배경색 설정
          title: Text(
            "비밀번호 변경",
            style: TextStyle(
              fontFamily: 'Pretendard-SemiBold',
              fontSize: 15,
              color: Color(0xFF3A281F),
              fontWeight: FontWeight.bold,
            ),
          ),
          content: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: pwdController,
                  decoration: InputDecoration(
                    hintText: "새 비밀번호 입력",
                    hintStyle: TextStyle(
                      fontSize: 13,
                      fontFamily: 'Pretendard',
                      fontWeight: FontWeight.w400,
                      color: Colors.grey,
                    ),
                    labelStyle: TextStyle(
                      fontSize: 15,
                      fontFamily: 'Pretendard',
                      fontWeight: FontWeight.w500,
                      color: Color(0xff4E3E36),
                    ),
                    border: UnderlineInputBorder(
                      borderSide: BorderSide(
                        color: Color(0xff3A281F),
                      ),
                    ),
                    focusedBorder: UnderlineInputBorder(
                      borderSide: BorderSide(
                        color: Color(0xff3A281F),
                      ),
                    ),

                  ),
                  keyboardType: TextInputType.visiblePassword,
                  obscureText: true,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return '비밀번호를 입력해주세요.';
                    }
                    if (!isValidPassword(value)) {
                      return '최소 8자, 대문자, 소문자, 숫자,\n특수문자를 포함해야 합니다.';
                    }
                    return null;
                  },
                ),
                SizedBox(height: 10),
                TextFormField(
                  controller: pwd2Controller,
                  decoration: InputDecoration(
                    hintText: "새 비밀번호 확인",
                    hintStyle: TextStyle(
                      fontSize: 13,
                      fontFamily: 'Pretendard',
                      fontWeight: FontWeight.w400,
                      color: Colors.grey,
                    ),
                    labelStyle: TextStyle(
                      fontSize: 15,
                      fontFamily: 'Pretendard',
                      fontWeight: FontWeight.w500,
                      color: Color(0xff4E3E36),
                    ),
                    border: UnderlineInputBorder(
                      borderSide: BorderSide(
                        color: Color(0xff3A281F),
                      ),
                    ),
                    focusedBorder: UnderlineInputBorder(
                      borderSide: BorderSide(
                        color: Color(0xff3A281F),
                      ),
                    ),

                  ),
                  keyboardType: TextInputType.visiblePassword,
                  obscureText: true,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return '비밀번호 확인을 입력해주세요.';
                    }
                    if (value != pwdController.text) {
                      return '비밀번호가 일치하지 않습니다.';
                    }
                    return null;
                  },
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () async {
                if (_formKey.currentState?.validate() ?? false) {
                  try {
                    await _updatePwd(email, pwdController.text);
                    Navigator.of(context).pop();
                    ScaffoldMessenger.of(scaffoldContext).showSnackBar(
                      SnackBar(content: Text('비밀번호가 변경되었습니다.')),
                    );
                  } catch (error) {
                    Navigator.of(context).pop();
                    ScaffoldMessenger.of(scaffoldContext).showSnackBar(
                      SnackBar(content: Text('비밀번호 변경에 실패했습니다.')),
                    );
                  }
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Color(0xFFFFE458),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(5),
                ),
              ),
              child: Text(
                "변경",
                style: TextStyle(
                  fontFamily: 'Pretendard-SemiBold',
                  fontSize: 15,
                  color: Color(0xFF3A281F),
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Color(0xFF6D605A),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(5),
                ),
              ),
              child: Text(
                "취소",
                style: TextStyle(
                  fontFamily: 'Pretendard-SemiBold',
                  fontSize: 15,
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final searchId = Provider.of<SearchId>(context);
    final email = searchId.find?.email;
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
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              Text(
                '아이디: $email',
                style: TextStyle(
                  fontFamily: 'Pretendard-SemiBold',
                  fontSize: 18.0,
                  color: Color(0xFF3A281F),
                ),
              ),
              SizedBox(height: 20.0),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  ElevatedButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => LoginApp(),
                        ),
                      );
                    },
                    child: Text(
                      '로그인',
                      style: TextStyle(
                        fontFamily: 'Pretendard-SemiBold',
                        fontSize: 15,
                        color: Color(0xFF3A281F),
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Color(0xFFFFE458),
                      foregroundColor: Color(0xFF3A281F),
                      minimumSize: Size(100, 50),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(5),
                      ),
                    ),
                  ),
                  SizedBox(width: 10),
                  ElevatedButton(
                    onPressed: () {
                      _showChangeDialog(context, email!);
                    },
                    child: Text(
                      '비밀번호 찾기',
                      style: TextStyle(
                        fontFamily: 'Pretendard-SemiBold',
                        fontSize: 15,
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Color(0xFF6D605A),
                      minimumSize: Size(100, 50),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(5),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
