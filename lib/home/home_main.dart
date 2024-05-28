import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'dart:async';
import 'package:wooki/login/Login_main.dart';

import '../firebase_options.dart';

void main() async{
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(FirstMainHome());
}

class FirstMainHome extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: FirstMain(),
    );
  }
}

class FirstMain extends StatefulWidget {
  @override
  _MyHomePageState createState() => _MyHomePageState();
}

class _MyHomePageState extends State<FirstMain> {
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
                    image: AssetImage('assets/img/home_B.png'),
                    fit: BoxFit.cover,
                  ),
                ),
                child: Center(
                  // child: Text(
                  //   '사랑하는 이들의 안전을 위한 실시간 위치 확인',
                  //   style: TextStyle(color: Colors.white, fontSize: 18),
                  // ),
                ),
              ),
              // 두 번째 이미지 페이지
              Container(
                decoration: BoxDecoration(
                  image: DecorationImage(
                    image: AssetImage('assets/img/home_A.png'),
                    fit: BoxFit.cover,
                  ),
                ),
                child: Center(
                  // child: Text(
                  //   '또 다른 페이지 내용',
                  //   style: TextStyle(color: Colors.white, fontSize: 18),
                  // ),
                ),
              ),
              // 세 번째 이미지 페이지
              Container(
                decoration: BoxDecoration(
                  image: DecorationImage(
                    image: AssetImage('assets/img/home_C.jpg'),
                    fit: BoxFit.cover,
                  ),
                ),
                child: Center(
                  // child: Text(
                  //   '또 다른 페이지 내용',
                  //   style: TextStyle(color: Colors.white, fontSize: 18),
                  // ),
                ),
              ),
            ],
          ),
          // 아래쪽 페이지 인디케이터
          Positioned(
            bottom: 80,
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
                child: Text('로그인하러가기'),
              ),
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
