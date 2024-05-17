import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class joinEx2 extends StatefulWidget {
  const joinEx2({super.key});

  @override
  join createState() => join();
}

class join extends State<joinEx2> {
  final FirebaseFirestore _fs = FirebaseFirestore.instance;//FirebaseFirestore에 저장할 변수
  final TextEditingController _name = TextEditingController();
  final TextEditingController _id = TextEditingController();
  final TextEditingController _pwd = TextEditingController();
  final TextEditingController _pwd1 = TextEditingController();
  final TextEditingController _email = TextEditingController();
  final TextEditingController _phone = TextEditingController();

  void _register() async {
    if (_pwd.text != _pwd1.text) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('패스워드 다르자너')),
      );
      return;
    }

    //id 중복체크
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

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(title: Text("회원가입")),
        body: Center(
          child: Padding(
            padding: EdgeInsets.all(20.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                TextField(
                  controller: _id,
                  decoration: InputDecoration(
                    labelText: "아이디",
                  ),
                ),
                SizedBox(height: 20),
                TextField(
                  controller: _name,
                  decoration: InputDecoration(
                    labelText: "이름",
                  ),
                ),
                SizedBox(height: 20),
                TextField(
                  controller: _pwd,
                  obscureText: true,
                  decoration: InputDecoration(
                    labelText: "비밀번호",
                  ),
                ),
                SizedBox(height: 20),
                TextField(
                  controller: _pwd1,
                  obscureText: true,
                  decoration: InputDecoration(
                    labelText: "비밀번호확인",
                  ),
                ),
                SizedBox(height: 20),
                TextField(
                  controller: _email,
                  decoration: InputDecoration(
                    labelText: "이메일",
                  ),
                ),
                SizedBox(height: 20),
                TextField(
                  controller: _phone,
                  decoration: InputDecoration(
                    labelText: "저나버노",
                  ),
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
    );
  }
}
