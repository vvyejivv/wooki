import 'package:flutter/material.dart';

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
  final TextEditingController phoneController = TextEditingController();
  final TextEditingController codeController = TextEditingController();

  String foundID = ''; // 찾은 아이디를 저장할 변수

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('아이디 찾기'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              Text(
                '아이디 찾기 성공',
                style: TextStyle(fontSize: 24.0, fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 20.0),
              Text(
                '아이디: $foundID',
                style: TextStyle(fontSize: 18.0),
              ),
              SizedBox(height: 20.0),
              ElevatedButton(
                onPressed: () {
                  // 로그인 버튼을 눌렀을 때의 동작 추가
                  // 여기서는 여기서는 해당 동작을 추가하지 않았습니다.
                },
                child: Text('로그인'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
