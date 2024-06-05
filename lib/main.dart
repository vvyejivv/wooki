import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'dart:async';
import 'package:wooki/login/Login_main.dart';
import 'package:provider/provider.dart';
import 'package:wooki/find/search_id.dart';
import '../firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => SearchId()),
      ],
      child: FirstMainHome(),
    ),
  );
}

class FirstMainHome extends StatelessWidget {

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      theme: ThemeData(
        primarySwatch: Colors.blue,
        fontFamily: 'Pretendard', // 전체 앱에 적용될 기본 폰트 설정
        textTheme: TextTheme(
          bodyLarge: TextStyle(fontFamily: 'Pretendard'),
          bodyMedium: TextStyle(fontFamily: 'Pretendard'),
          bodySmall: TextStyle(fontFamily: 'Pretendard'),
          displayLarge: TextStyle(fontFamily: 'Pretendard'),
          displayMedium: TextStyle(fontFamily: 'Pretendard'),
          displaySmall: TextStyle(fontFamily: 'Pretendard'),
          headlineLarge: TextStyle(fontFamily: 'Pretendard'),
          headlineMedium: TextStyle(fontFamily: 'Pretendard'),
          headlineSmall: TextStyle(fontFamily: 'Pretendard'),
          titleLarge: TextStyle(fontFamily: 'Pretendard'),
          titleMedium: TextStyle(fontFamily: 'Pretendard'),
          titleSmall: TextStyle(fontFamily: 'Pretendard'),
          labelLarge: TextStyle(fontFamily: 'Pretendard'),
          labelMedium: TextStyle(fontFamily: 'Pretendard'),
          labelSmall: TextStyle(fontFamily: 'Pretendard'),
        ),
      ),
      themeMode: ThemeMode.system,
      home: FirstMain(),
    );
  }
}

class FirstMain extends StatefulWidget {
  @override
  _FirstMainState createState() => _FirstMainState();
}

class _FirstMainState extends State<FirstMain> {
  PageController _pageController = PageController();
  int _currentPage = 0;
  final int _totalPages = 3;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _pageController.addListener(() {
      if (_pageController.page != null) {
        int next = _pageController.page!.round();
        if (_currentPage != next) {
          setState(() {
            _currentPage = next;
          });
        }
      }
    });

    _timer = Timer.periodic(Duration(seconds: 5), (Timer timer) {
      if (_currentPage < _totalPages - 1) {
        _currentPage++;
      } else {
        _currentPage = 0;
      }
      _pageController.animateToPage(
        _currentPage,
        duration: Duration(milliseconds: 500),
        curve: Curves.easeIn,
      );
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          PageView(
            controller: _pageController,
            onPageChanged: (int page) {
              setState(() {
                _currentPage = page;
              });
            },
            children: [
              // 첫 번째 이미지 페이지
              Container(
                decoration: BoxDecoration(
                  image: DecorationImage(
                    image: AssetImage('assets/img/home_1.jpg'),
                    fit: BoxFit.cover,
                  ),
                ),
              ),
              // 두 번째 이미지 페이지
              Container(
                decoration: BoxDecoration(
                  image: DecorationImage(
                    image: AssetImage('assets/img/home_2.jpg'),
                    fit: BoxFit.cover,
                  ),
                ),
              ),
              // 세 번째 이미지 페이지
              Container(
                decoration: BoxDecoration(
                  image: DecorationImage(
                    image: AssetImage('assets/img/home_3.jpg'),
                    fit: BoxFit.cover,
                  ),
                ),
              ),
            ],
          ),
          // 아래쪽 페이지 인디케이터
          Positioned(
            bottom: 120,
            left: 0,
            right: 0,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                for (int i = 0; i < _totalPages; i++)
                  if (i == _currentPage) ...[
                    _buildPageIndicator(true),
                  ] else
                    _buildPageIndicator(false),
              ],
            ),
          ),
          // 아래쪽에 로그인 버튼
          Positioned(
            bottom: 30,
            left: 0,
            right: 0,
            child: Center(
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => LoginApp()),
                    );
                  },
                  child: Text(
                    '로그인 하러가기',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Color(0xffFFDB1C),  // 버튼 배경색
                    foregroundColor: Color(0xff3A281F),  // 버튼 텍스트 색상
                    padding: EdgeInsets.symmetric(horizontal: 100, vertical: 15),  // 버튼 크기 조절
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8.0),  // 버튼 모서리 둥글게 설정
                    ),
                    elevation: 5,  // 버튼 그림자 설정
                  ),
                )
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPageIndicator(bool isCurrentPage) {
    return AnimatedContainer(
      duration: Duration(milliseconds: 150),
      margin: EdgeInsets.symmetric(horizontal: 8.0),
      height: isCurrentPage ? 12.0 : 8.0,
      width: isCurrentPage ? 12.0 : 8.0,
      decoration: BoxDecoration(
        color: isCurrentPage ? Colors.white : Colors.white.withOpacity(0.5),
        borderRadius: BorderRadius.all(Radius.circular(12)),
      ),
    );
  }
}
