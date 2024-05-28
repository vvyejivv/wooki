import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import '../firebase_options.dart';
import 'package:firebase_storage/firebase_storage.dart' as firebase_storage;
import 'dart:io';
import 'package:image_picker/image_picker.dart';


void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(const JoinEx2());
}

bool isValidName(String name) {
  String nameRegex = r'^[가-힣]{1,5}$|^[a-zA-Z]{1,10}$'; //한글로 1자에서 5자까지 또는 영어로 1자에서 10자까지
  return RegExp(nameRegex).hasMatch(name);
}

bool isValidPassword(String password) {
  String passwordRegex = r'^(?=.*?[A-Z])(?=.*?[a-z])(?=.*?[0-9])(?=.*?[!@#\$&*~]).{8,}$';
  //최소 8자 이상이어야 하며, 대문자, 소문자, 숫자, 특수문자 중에서 4종류가 모두 포함되어야
  return RegExp(passwordRegex).hasMatch(password);
}

bool isValidPhoneNumber(String phoneNumber) {
  String phoneNumberRegex = r'^\d{9,11}$';// 9자리에서 11자리의 숫자
  return RegExp(phoneNumberRegex).hasMatch(phoneNumber);
}


bool _isValidEmail(String email) {
  return RegExp(r'^[a-zA-Z0-9][a-zA-Z0-9._%+-]*@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$').hasMatch(email);
}//이메일 주소는 알파벳 또는 숫자로 시작해야 함, @ 다음에 도메인 이름

class JoinEx2 extends StatelessWidget {
  const JoinEx2({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: JoinScreen(),
    );
  }
}

class JoinScreen extends StatefulWidget {
  const JoinScreen({Key? key}) : super(key: key);

  @override
  _JoinScreenState createState() => _JoinScreenState();
}

class _JoinScreenState extends State<JoinScreen> {
  File? _imageFile;
  final FirebaseFirestore _fs = FirebaseFirestore.instance;
  final TextEditingController _name = TextEditingController();
  final TextEditingController _pwd = TextEditingController();
  final TextEditingController _pwd1 = TextEditingController();
  final TextEditingController _email = TextEditingController();
  final picker = ImagePicker();

  String _imageURL = '';

  void _showSnackBar(BuildContext context, String message) {
    if (message.isNotEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message)),
      );
    }
  }

  final TextEditingController _phone = TextEditingController();
  final TextEditingController _todayDateController = TextEditingController();
  final TextEditingController _verificationCodeController = TextEditingController();
  final String emailLabelText = "이메일";
  final String emailHintText = "이메일을 입력하세요";

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


  void _checkPhoneNumber() {
    if (_phone.text.isEmpty) {
      _showSnackBar(context,'전화번호를 입력하세요.');
      return;
    }

    if (!isValidPhoneNumber(_phone.text)) {
      _showSnackBar(context,'유효하지 않은 전화번호 형식입니다. 다시 입력하세요.');
      return;
    }
  }

  // Future<void> _selectImage() async {
  //   final pickedFile = await picker.getImage(source: ImageSource.gallery); // 갤러리에서 이미지 선택
  //   setState(() {
  //     _imageFile = File(pickedFile.path); // 선택한 이미지 파일의 경로 설정
  //   });
  // }

  Future<void> _uploadImage() async {
    try {
      if (_imageFile != null) {
        firebase_storage.Reference ref = firebase_storage.FirebaseStorage.instance.ref().child('images/${DateTime.now().toString()}');
        firebase_storage.UploadTask uploadTask = ref.putFile(_imageFile!);
        await uploadTask.whenComplete(() async {
          _imageURL = await ref.getDownloadURL(); // 업로드된 이미지의 URL 가져오기
        });
      } else {
        print('Image file is null. Upload task skipped.');
      }
    } catch (e) {
      print('Error uploading image: $e');
    }
  }

  void _register() async {
    if (!_isVerified) {
      _showSnackBar(context,'먼저 인증을 완료하세요.');
      return;
    }

    if (_name.text.isEmpty ||
        _pwd.text.isEmpty ||
        _pwd1.text.isEmpty ||
        _email.text.isEmpty ||
        _phone.text.isEmpty) {
      _showSnackBar(context, '모든 필드를 입력하세요.');
      return;
    }

    // 이름 유효성 검사 추가
    if (!isValidName(_name.text)) {
      _showSnackBar(context,'이름은 한글로 1자에서 5자까지 또는 영어로 1자에서 10자까지 입력하세요.');
      return;
    }

    if (!isValidPassword(_pwd.text)) {
      _showSnackBar(context,'비밀번호가 유효하지 않습니다. 비밀번호는 최소 8자 이상이어야 하며, 대문자, 소문자, 숫자, 특수문자 중에서 4종류 이상이 포함되어야 합니다.');
      return;
    }

    if (_pwd.text != _pwd1.text) {
      _showSnackBar(context,'비밀번호가 다릅니다.');
      return;
    }

    if (_pwd.text.isEmpty || _pwd.text != _pwd1.text) {
      _showSnackBar(context,'비밀번호를 확인하세요.');
      return;
    }

      // 이미지 업로드
      await _uploadImage();

    try {
      await _fs.collection('USERLIST').add({
        'name': _name.text,
        'pwd': _pwd.text,
        'email': _email.text,
        'phone': _phone.text,
        'todayDate': FieldValue.serverTimestamp(), // 서버 타임스탬프 사용
        'imagePath': 'https://firebasestorage.googleapis.com/v0/b/wooki-3f810.appspot.com/o/images%2FprofileImage.jpg?alt=media&token=465c06f2-7f99-46d7-8b5b-f506166a247b', // 이미지 경로 추가
        'family': false, // family 필드 추가
        'isAdmin' :false, // admin 필드 추가
        'familyLinked' :false,
      });

      _showSnackBar(context,'가입되었음!!');
      _name.clear();
      _pwd.clear();
      _pwd1.clear();
      _email.clear();
      _phone.clear();
      _verificationCodeController.clear();
    } catch (e) {
      _showSnackBar(context,'Error: $e');
      print('Error adding document: $e'); // 에러 로그 출력
    }
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
      _showSnackBar(context,'인증 코드를 입력하세요.');
      return;
    }

    if (enteredCode == _generatedCode) {
      setState(() {
        _isVerified = true;
      });
      _showSnackBar(context,'인증 완료되었습니다.');
    } else {
      _showSnackBar(context,'인증 코드가 다릅니다. 다시 시도해주세요.');
    }
  }

  String _generateRandomCode() {
    const chars = '0123456789';
    final random = Random();
    return String.fromCharCodes(Iterable.generate(
        6, (_) => chars.codeUnitAt(random.nextInt(chars.length))));
  }

  void _checkEmail() async {
    if (_email.text.isEmpty) {
      _showSnackBar(context, '이메일을 입력하세요.');
      return;
    }

    if (!_isValidEmail(_email.text)) {
      _showInvalidEmailMessage();
      return;
    }

    try {
      var checkEmail = await _checkDuplicateEmail(_email.text);

      if (checkEmail.docs.isNotEmpty) {
        _showSnackBar(context,'이미 존재하는 이메일입니다.');
        _email.clear();
      } else {
        _showSnackBar(context,'사용 가능한 이메일입니다.');
      }
    } catch (e) {
      _showSnackBar(context,'이메일 확인 중 오류가 발생했습니다: $e');
    }
  }

  void _showInvalidEmailMessage() {
    _showSnackBar(context,'올바른 이메일 형식을 입력하세요.');
  }

  //사용자 목록을 조회하여 주어진 이메일과 일치하는 사용자를 찾는 역할
  Future<QuerySnapshot> _checkDuplicateEmail(String email) async {
    return await _fs.collection('USERLIST').where('email', isEqualTo: email).get();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color.fromARGB(255, 255, 253, 239),
      appBar: AppBar(
        title: Text("회원가입", style: TextStyle(fontFamily: 'Pretendard', fontWeight: FontWeight.w500)),
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
                  // TextField(//예전 버튼 따로 있던 코드
                  //   style: TextStyle(fontFamily: 'Pretendard', fontWeight: FontWeight.bold),
                  //   controller: _email,
                  //   decoration: InputDecoration(
                  //     labelText: "이메일",
                  //     hintText: "이메일을 입력하세요",
                  //     border: OutlineInputBorder(),
                  //   ),
                  // ),
                  // SizedBox(height: 20),
                  // Row(
                  //   children: [
                  //     ElevatedButton(
                  //       onPressed: _checkEmail,
                  //       style: ElevatedButton.styleFrom(
                  //         backgroundColor: Color.fromRGBO(255, 219, 28, 1),
                  //       ),
                  //       child: Text(
                  //         '중복 확인',
                  //         style: TextStyle(
                  //             color: Colors.black,
                  //             fontFamily: 'Pretendard',
                  //             fontWeight: FontWeight.bold), // 텍스트 색상을 검정색으로 변경
                  //       ),
                  //     ),
                  //   ],
                  // ),
                  TextField(
                    controller: _email,
                    decoration: InputDecoration(
                      labelText: "이메일",
                      hintText: "이메일을 입력하세요",
                      border: OutlineInputBorder(),
                      suffixIcon: ElevatedButton(
                        onPressed: _checkEmail,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Color.fromRGBO(255, 219, 28, 1),
                        ),
                        child: Text(
                          '중복 확인',
                          style: TextStyle(
                            color: Colors.black,
                            fontFamily: 'Pretendard',
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ),
                  ),
                  SizedBox(height: 20), // 여백 추가
                  TextField(
                    style: TextStyle(fontFamily: 'Pretendard', fontWeight: FontWeight.bold),
                    controller: _name,
                    decoration: InputDecoration(
                      labelText: "이름",
                      border: OutlineInputBorder(),
                    ),
                  ),
                  SizedBox(height: 20),
                  TextField(
                    style: TextStyle(fontFamily: 'Pretendard', fontWeight: FontWeight.bold),
                    controller: _pwd,
                    onChanged: (value) {
                      setState(() {}); // 입력이 변경될 때마다 화면을 다시 그려줌
                    },
                    obscureText: true,
                    decoration: InputDecoration(
                      labelText: "비밀번호",
                      border: OutlineInputBorder(),
                    ),
                  ),
                  SizedBox(height: 20),
                  TextField(
                    style: TextStyle(fontFamily: 'Pretendard', fontWeight: FontWeight.bold),
                    controller: _pwd1,
                    obscureText: true,
                    decoration: InputDecoration(
                      labelText: "비밀번호 확인",
                      border: OutlineInputBorder(),
                    ),
                  ),
                  SizedBox(height: 20),
                  TextField(
                    style: TextStyle(fontFamily: 'Pretendard', fontWeight: FontWeight.bold),
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
                        onPressed: () {
                          _checkPhoneNumber(); // 전화번호 유효성 확인
                          if (_phone.text.isNotEmpty && isValidPhoneNumber(_phone.text)) {
                            sendSMS(); // 유효성 확인 후 SMS 보내기
                          }
                        },
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
                      style: TextStyle(fontFamily: 'Pretendard', fontWeight: FontWeight.bold),
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
    );
  }
}