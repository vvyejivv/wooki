import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_naver_login/flutter_naver_login.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:kakao_flutter_sdk/kakao_flutter_sdk.dart';
import 'package:wooki/firebase_options.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'Logout.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:kakao_flutter_sdk_common/kakao_flutter_sdk_common.dart';
import 'package:provider/provider.dart';
import 'package:wooki/main.dart';
import 'Session.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await SharedPreferences.getInstance();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  // 웹 환경에서 카카오 로그인을 정상적으로 완료하려면 runApp() 호출 전 아래 메서드 호출 필요
  WidgetsFlutterBinding.ensureInitialized();

  // runApp() 호출 전 Flutter SDK 초기화
  KakaoSdk.init(
    nativeAppKey: '62b9387218f4e9061c4d487ab5d728f9',
    javaScriptAppKey: '4ad5aa841d079ff244bbdbbad04eae08',
  );
  runApp(const LoginApp());
}

class LoginApp extends StatefulWidget {
  const LoginApp({super.key});

  @override
  State<LoginApp> createState() => _MyAppState();
}

class _MyAppState extends State<LoginApp> {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(home: MyWidget());
  }
}

class MyWidget extends StatefulWidget {
  const MyWidget({super.key});

  @override
  State<MyWidget> createState() => _MyWidgetState();
}

class _MyWidgetState extends State<MyWidget> {
  final FirebaseFirestore _fs = FirebaseFirestore.instance;


  //네이버 로그인
  void _naverLogin() async {
    try {
      final NaverLoginResult res = await FlutterNaverLogin.logIn();
      print('accessToken = ${res.accessToken}');
      print('id = ${res.account.id}');
      print('email = ${res.account.email}');
      print('name = ${res.account.name}');
      var _id = res.account.id;
      var _email = res.account.email;
      var _name = res.account.name;

      if (_id != null && _email != null && _name != null) {
        _userCheck(_email);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('네이버 로그인에 실패하였습니다.')),
        );
      }
    } catch (error) {
      print(error);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('네이버 로그인에 실패하였습니다. $error')),
      );
    }
  }

  //구글 로그인
  Future<void> signInWithGoogle() async {
    try {
      // 사용자가 로그인하는 것을 기다림
      final GoogleSignInAccount? googleUser = await GoogleSignIn().signIn();

      // 로그인한 사용자의 정보를 얻음
      final GoogleSignInAuthentication? googleAuth =
          await googleUser?.authentication;

      // 새로운 자격 증명을 생성함
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth?.accessToken,
        idToken: googleAuth?.idToken,
      );

      // 로그인 성공 시 UserCredential을 반환함
      final userCredential =
          await FirebaseAuth.instance.signInWithCredential(credential);

      // 사용자의 이메일 주소에 접근함
      final userEmail = userCredential.user?.email;
      print(userEmail);

      // 사용자의 이메일을 이용하여 원하는 작업을 수행함
      _userCheck(userEmail);
    } catch (error) {
      print(error);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('구글 로그인에 실패하였습니다. $error')),
      );
    }
  }

  //카카오 로그인
  Future<void> _kakaoLogin() async {
    // 카카오톡 실행 가능 여부 확인
    // 카카오톡 실행이 가능하면 카카오톡으로 로그인, 아니면 카카오계정으로 로그인
    if (await isKakaoTalkInstalled()) {
      try {
        var provider = OAuthProvider('oidc.wooki');
        OAuthToken token = await UserApi.instance.loginWithKakaoAccount();
        var credential = provider.credential(
          idToken: token.idToken,
          accessToken: token.accessToken,
        );
        FirebaseAuth.instance.signInWithCredential(credential);
        await UserApi.instance.loginWithKakaoTalk();
        print('카카오톡으로 로그인 성공');

        // 사용자 정보 가져오기
        final userProfile = await UserApi.instance.me();
        final userEmail = await userProfile.kakaoAccount!.email;
        print('카카오 이메일 : $userEmail');

        // 사용자 정보를 가져온 후에 다음 페이지로 이동
        _userCheck(userEmail);

      } catch (error) {
        print('카카오톡으로 로그인 실패 $error');

        // 사용자가 카카오톡 설치 후 디바이스 권한 요청 화면에서 로그인을 취소한 경우,
        // 의도적인 로그인 취소로 보고 카카오계정으로 로그인 시도 없이 로그인 취소로 처리 (예: 뒤로 가기)
        if (error is PlatformException && error.code == 'CANCELED') {
          return;
        }
        // 카카오톡에 연결된 카카오계정이 없는 경우, 카카오계정으로 로그인
        try {
          var provider = OAuthProvider('oidc.wooki');
          OAuthToken token = await UserApi.instance.loginWithKakaoAccount();
          var credential = provider.credential(
            idToken: token.idToken,
            accessToken: token.accessToken,
          );
          FirebaseAuth.instance.signInWithCredential(credential);
          await UserApi.instance.loginWithKakaoAccount();
          print('카카오계정으로 로그인 성공');

          // 사용자 정보 가져오기
          final userProfile = await UserApi.instance.me();
          final userEmail = await userProfile.kakaoAccount!.email;
          print('카카오 이메일 : $userEmail');

          // 사용자 정보를 가져온 후에 다음 페이지로 이동
          _userCheck(userEmail);

        } catch (error) {
          print('카카오계정으로 로그인 실패 $error');
        }
      }
    } else {
      try {
        var provider = OAuthProvider('oidc.wooki');
        OAuthToken token = await UserApi.instance.loginWithKakaoAccount();
        var credential = provider.credential(
          idToken: token.idToken,
          accessToken: token.accessToken,
        );
        FirebaseAuth.instance.signInWithCredential(credential);
        await UserApi.instance.loginWithKakaoAccount();
        print('카카오계정으로 로그인 성공');

        // 사용자 정보 가져오기
        final userProfile = await UserApi.instance.me();
        final userEmail = await userProfile.kakaoAccount!.email;
        print('카카오 이메일 : $userEmail');

        // 사용자 정보를 가져온 후에 다음 페이지로 이동
        _userCheck(userEmail);

      } catch (error) {
        print('카카오계정으로 로그인 실패 $error');
      }
    }
  }


  void _userCheck(email) async {
    final userDocs =
        await _fs.collection('USERLIST').where('email', isEqualTo: email).get();
    print(email);
    if (userDocs.docs.isNotEmpty) {
      Navigator.push(
          context, MaterialPageRoute(builder: (context) => LogoutApp()));
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('오류')),
      );
    }
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Color(0xFFFFFDEF),
      ),
      body: Container(
        color: Color(0xFFFFFDEF),
        padding: const EdgeInsets.all(18.0),
        child: Column(
          children: [
            UserLogin(),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                GestureDetector(
                  onTap: _naverLogin,
                  child: Image.asset(
                    'assets/img/naverBtn2.png',
                    height: 40,
                  ),
                ),
                SizedBox(width: 16),
                GestureDetector(
                  onTap: () => signInWithGoogle(),
                  child: Image.asset(
                    'assets/img/googleBtn2.png',
                    height: 40,
                  ),
                ),
                SizedBox(width: 16),
                GestureDetector(
                  onTap: _kakaoLogin,
                  child: Image.asset(
                    'assets/img/kakao-icon.png',
                    height: 40,
                  ),
                ),
              ],
            )
          ],
        ),
      ),
    );
  }
}


class UserLogin extends StatefulWidget {
  @override
  State<UserLogin> createState() => _UserLoginState();
}

class _UserLoginState extends State<UserLogin> {
  final TextEditingController _userEmail = TextEditingController();
  final TextEditingController _userPwd = TextEditingController();
  final FirebaseFirestore _fs = FirebaseFirestore.instance;

  void _login() async {
    String userEmail = _userEmail.text;
    String userPwd = _userPwd.text;
    final userDocs = await _fs
        .collection('USERLIST')
        .where('email', isEqualTo: userEmail)
        .where('pwd', isEqualTo: userPwd)
        .get();

    if (userDocs.docs.isNotEmpty) {
      var session = Provider.of<Session>(context, listen: false);
      var users = userDocs.docs.first.data();
      session.login(users['name'], users['email'], users['phone']);

      Navigator.push(
          context, MaterialPageRoute(builder: (context) => MainPage()));
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('이메일 또는 패스워드를 다시 확인해주세요.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        children: [
          Container(
            margin: EdgeInsets.only(bottom: 20, top: 40),
            padding: EdgeInsets.all(20),
            child: Image.asset(
              'assets/img/wooki2.png',
              width: 150,
            ),
          ),
          Container(
            padding: EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(10),
            ),
            child: TextField(
              controller: _userEmail,
              decoration: InputDecoration(
                hintText: '이메일을 입력해주세요.',
                border: InputBorder.none,
              ),
            ),
          ),
          SizedBox(height: 10),
          Container(
            padding: EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(10),
            ),
            child: TextField(
              controller: _userPwd,
              obscureText: true,
              decoration: InputDecoration(
                hintText: '비밀번호를 입력해주세요.',
                border: InputBorder.none,
              ),
            ),
          ),
          SizedBox(height: 15),
          ElevatedButton(
            onPressed: _login,
            child: Text('로그인'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Color(0xFFFFE458),
              foregroundColor: Color(0xFF3A281F),
              minimumSize: Size(double.infinity, 50),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(5),
              ),
            ),
          ),
          SizedBox(height: 30),
        ],
      ),
    );
  }
}


