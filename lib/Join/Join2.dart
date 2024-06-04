import 'dart:io';
import 'dart:math';
import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_storage/firebase_storage.dart' as firebase_storage;
import 'package:image_picker/image_picker.dart';
import '../firebase_options.dart';
import 'package:wooki/login/Login_main.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(const JoinEx2());
}

bool isValidName(String name) {
  String nameRegex = r'^[가-힣]{1,5}$|^[a-zA-Z]{1,10}$';
  return RegExp(nameRegex).hasMatch(name);
}

bool isValidPassword(String password) {
  String passwordRegex = r'^(?=.*?[A-Z])(?=.*?[a-z])(?=.*?[0-9])(?=.*?[!@#\$&*~]).{8,}$';
  return RegExp(passwordRegex).hasMatch(password);
}

bool isValidPhoneNumber(String phoneNumber) {
  String phoneNumberRegex = r'^\d{9,11}$';
  return RegExp(phoneNumberRegex).hasMatch(phoneNumber);
}

bool _isValidEmail(String email) {
  return RegExp(r'^[a-zA-Z0-9][a-zA-Z0-9._%+-]*@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$').hasMatch(email);
}

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

  String _imageURL = 'https://firebasestorage.googleapis.com/v0/b/wooki-3f810.appspot.com/o/images%2FprofileImage.jpg?alt=media&token=465c06f2-7f99-46d7-8b5b-f506166a247b';

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
      _showSnackBar(context, '전화번호를 입력하세요.');
      return;
    }

    if (!isValidPhoneNumber(_phone.text)) {
      _showSnackBar(context, '유효하지 않은 전화번호 형식입니다. 다시 입력하세요.');
      return;
    }
  }

  Future<void> _uploadImage() async {
    try {
      if (_imageFile != null) {
        firebase_storage.Reference ref = firebase_storage.FirebaseStorage.instance.ref().child('images/${DateTime.now().toString()}');
        firebase_storage.UploadTask uploadTask = ref.putFile(_imageFile!);
        await uploadTask.whenComplete(() async {
          _imageURL = await ref.getDownloadURL(); // 업로드된 이미지의 URL 가져오기
          print('Image uploaded successfully. URL: $_imageURL');
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
      _showSnackBar(context, '먼저 인증을 완료하세요.');
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

    if (!isValidName(_name.text)) {
      _showSnackBar(context, '이름은 한글로 1자에서 5자까지 또는 영어로 1자에서 10자까지 입력하세요.');
      return;
    }

    if (!isValidPassword(_pwd.text)) {
      _showSnackBar(context, '비밀번호가 유효하지 않습니다. 비밀번호는 최소 8자 이상이어야 하며, 대문자, 소문자, 숫자, 특수문자 중에서 4종류 이상이 포함되어야 합니다.');
      return;
    }

    if (_pwd.text != _pwd1.text) {
      _showSnackBar(context, '비밀번호가 다릅니다.');
      return;
    }

    await _uploadImage();

    try {
      await _fs.collection('USERLIST').add({
        'name': _name.text,
        'pwd': _pwd.text,
        'email': _email.text,
        'phone': _phone.text,
        'todayDate': FieldValue.serverTimestamp(),
        'imagePath': _imageURL,
        'family': false,
        'isAdmin': false,
        'familyLinked': false,
      });

      _showSnackBar(context, '가입되었음!!');
      _name.clear();
      _pwd.clear();
      _pwd1.clear();
      _email.clear();
      _phone.clear();
      _verificationCodeController.clear();
    } catch (e) {
      _showSnackBar(context, 'Error: $e');
      print('Error adding document: $e');
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
    if (enteredCode.isEmpty) {
      _showSnackBar(context, '인증 코드를 입력하세요.');
      return;
    }

    if (enteredCode == _generatedCode) {
      setState(() {
        _isVerified = true;
      });
      _showSnackBar(context, '인증 완료되었습니다.');
    } else {
      _showSnackBar(context, '인증 코드가 다릅니다. 다시 시도해주세요.');
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
        _showSnackBar(context, '이미 존재하는 이메일입니다.');
        _email.clear();
      } else {
        _showSnackBar(context, '사용 가능한 이메일입니다.');
      }
    } catch (e) {
      _showSnackBar(context, '이메일 확인 중 오류가 발생했습니다: $e');
    }
  }

  void _showInvalidEmailMessage() {
    _showSnackBar(context, '올바른 이메일 형식을 입력하세요.');
  }

  Future<QuerySnapshot> _checkDuplicateEmail(String email) async {
    return await _fs.collection('USERLIST').where('email', isEqualTo: email).get();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFFFFFDEF),
      appBar: AppBar(
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Color(0xff3A281F),),
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => LoginApp()),
            );
          },
        ),
        title: Text(
          "회원가입",
          style: TextStyle(
            fontFamily: 'Pretendard',
            fontWeight: FontWeight.w700,
            color: Color(0xff3A281F),
          ),
        ),
        backgroundColor: Color(0xFFFFFDEF),
        elevation: 0,
        centerTitle: true,
        bottom: PreferredSize(
          preferredSize: Size.fromHeight(4.0),
          child: Container(
            color: Color(0xff3A281F), // 밑줄 색상
            height: 1.0,
          ),
        ),
      ),
      body: Container(
        padding: EdgeInsets.all(20.0),
        child: SingleChildScrollView(
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.start,
              children: [
                SizedBox(height: 10),
                GestureDetector(
                  onTap: () async {
                    final pickedFile = await picker.pickImage(source: ImageSource.gallery);
                    if (pickedFile != null) {
                      setState(() {
                        _imageFile = File(pickedFile.path);
                      });
                    } else {
                      // 사용자가 이미지 선택을 취소했을 때 기본 이미지로 설정
                      setState(() {
                        _imageFile = null;
                      });
                      showDialog(
                        context: context,
                        builder: (BuildContext context) {
                          return AlertDialog(
                            title: Text('사진 선택 취소'),
                            content: Text('사진 선택을 취소하셨습니다. 기본 이미지로 복귀합니다.'),
                            actions: <Widget>[
                              TextButton(
                                child: Text('확인'),
                                onPressed: () {
                                  Navigator.of(context).pop(); // 대화 상자를 닫습니다.
                                },
                              ),
                            ],
                          );
                        },
                      );
                    }
                  },
                  child: Container(
                    width: 120, // CircleAvatar의 두 배 크기
                    height: 120, // CircleAvatar의 두 배 크기
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: Color(0xFFFFDB1C), // 테두리 색상
                        width: 3.0, // 테두리 두께
                      ),
                    ),
                    child: CircleAvatar(
                      radius: 10,
                      backgroundColor: Colors.transparent, // 배경 투명
                      child: _imageFile == null
                          ? Text(
                        '프로필 등록하기',
                        style: TextStyle(
                          fontSize: 14,
                          color: Color(0xff4E3E36),
                          fontWeight: FontWeight.bold,
                        ),
                      )
                          : null,
                      backgroundImage: _imageFile != null
                          ? FileImage(_imageFile!) as ImageProvider
                          : null,
                    ),
                  ),
                ),
                SizedBox(height: 20),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _email,
                        decoration: InputDecoration(
                          labelText: emailLabelText,
                          hintText: emailHintText,
                          hintStyle: TextStyle(
                            fontSize: 13, // 힌트 텍스트 크기
                            fontFamily: 'Pretendard',
                            fontWeight: FontWeight.w400,
                            color: Colors.grey, // 힌트 텍스트 색상
                          ),
                          labelStyle: TextStyle(
                            fontSize: 15, // 원하는 글씨 크기
                            fontFamily: 'Pretendard',
                            fontWeight: FontWeight.w500,
                            color: Color(0xff4E3E36), // 텍스트 색상 (필요한 경우)
                          ),
                          border: UnderlineInputBorder(
                            borderSide: BorderSide(
                              color: Color(0xff3A281F), // 밑줄 색상
                            ),
                          ),
                          focusedBorder: UnderlineInputBorder(
                            borderSide: BorderSide(
                              color: Color(0xff3A281F), // 포커스된 밑줄 색상
                            ),
                          ),
                        ),
                      ),
                    ),
                    ElevatedButton(
                      onPressed: _checkEmail,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Color(0xFFFFE458),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        )
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

                  ],
                ),
                SizedBox(height: 20),
                TextField(
                  controller: _name,
                  decoration: InputDecoration(
                    labelText: "이름",
                    hintText: "실명을 입력하세요",
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
                ),
                SizedBox(height: 20),
                TextField(
                  controller: _pwd,
                  onChanged: (value) {
                    setState(() {});
                  },
                  obscureText: true,
                  decoration: InputDecoration(
                    labelText: "비밀번호",
                    hintText: "비밀번호를 입력하세요.",
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
                ),
                SizedBox(height: 20),
                TextField(
                  controller: _pwd1,
                  obscureText: true,
                  decoration: InputDecoration(
                    labelText: "비밀번호 확인",
                    hintText: "비밀번호를 입력하세요.",
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
                ),
                SizedBox(height: 20),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _phone,
                        decoration: InputDecoration(
                          labelText: "전화번호",
                          hintText: "'-' 구분없이 입력해주세요.",
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
                      ),
                    ),
                    ElevatedButton(
                      onPressed: () {
                        _checkPhoneNumber();
                        if (_phone.text.isNotEmpty && isValidPhoneNumber(_phone.text)) {
                          sendSMS();
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Color(0xFFFFE458),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: Text(
                        '휴대폰 인증',
                        style: TextStyle(
                          color: Colors.black,
                          fontFamily: 'Pretendard',
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 20),
                if (_isVerificationSent) ...[
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _verificationCodeController,
                          decoration: InputDecoration(
                            labelText: "인증 코드 입력",
                            hintText: "인증번호 입력",
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
                        ),
                      ),
                      ElevatedButton(
                        onPressed: verifyCode,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Color(0xFFFFE458),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        child: Text(
                          '인증하기',
                          style: TextStyle(
                            color: Colors.black,
                            fontFamily: 'Pretendard',
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
                SizedBox(height: 20),
                    ElevatedButton(
                      onPressed: _register,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Color(0xFFFFE458),
                        foregroundColor: Color(0xFF3A281F),
                        minimumSize: Size(double.infinity, 50),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(5),
                        ),
                      ),
                      child: Text(
                        '가입하기',
                        style: TextStyle(
                          color: Colors.black,
                          fontFamily: 'Pretendard',
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                    SizedBox(height: 5,), // Add space between buttons
                    ElevatedButton(
                      onPressed: () {
                        Navigator.pop(context);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Color(0xFF6D605A),
                        minimumSize: Size(double.infinity, 50),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(5),
                        ),
                      ),
                      child: Text(
                        '취소',
                        style: TextStyle(
                          color: Colors.white,
                          fontFamily: 'Pretendard',
                          fontWeight: FontWeight.w500,
                        ),
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
    );
  }
}
