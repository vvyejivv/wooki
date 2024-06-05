import 'package:flutter/material.dart';
import 'package:flutter_chat_ui/flutter_chat_ui.dart';
import 'package:wooki/CustomerServiceCenter/user_chat_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'admin_chat_screen.dart';
import 'announcement.dart';
import 'asked_questions.dart';
import 'event_page.dart';
import 'firestore_service.dart';
import 'home_screen.dart';
import '../map/MapMain.dart';

class MainScreens extends StatefulWidget {
  const MainScreens({Key? key}) : super(key: key);

  @override
  State<MainScreens> createState() => _MainScreensState();
}

class _MainScreensState extends State<MainScreens>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController; // 탭 컨트롤러
  late SharedPreferences prefs; // SharedPreferences 인스턴스
  String? email; // 사용자 이메일
  bool isAdmin = false; // 관리자 여부
  late FirestoreService firestoreService; // Firestore 서비스 인스턴스

  @override
  void initState() {
    super.initState();
    firestoreService = FirestoreService(); // Firestore 서비스 초기화
    _tabController =
        TabController(length: 5, vsync: this); // 탭 컨트롤러 초기화 (탭 수: 5)
    _loadSessionData(); // 세션 데이터 로드
  }

  Future<void> _loadSessionData() async {
    prefs = await SharedPreferences.getInstance(); // SharedPreferences 인스턴스 초기화
    String? userEmail = prefs.getString('email'); // 이메일 불러오기
    if (userEmail != null) {
      bool adminStatus =
      await firestoreService.isAdminByEmail(userEmail); // 관리자 여부 확인
      setState(() {
        email = userEmail; // 사용자 이메일 설정
        isAdmin = adminStatus; // 관리자 여부 설정
      });
    }
  }

  @override
  void dispose() {
    _tabController.dispose(); // 탭 컨트롤러 해제
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
            '고객센터',
            style: TextStyle(color: Color(0xFF4E3E36), fontWeight: FontWeight.w500)
        ), // 앱 바 타이틀을 가운데로 정렬
        backgroundColor: Color(0xFFFFFDEF),
        leading: IconButton(
          icon:
          const Icon(Icons.arrow_back_ios_new_rounded, color: Color(0xFF4E3E36)),
          // 뒤로 가기 아이콘
          onPressed: () {
            if (email != null) {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => MapScreen(
                    userId: email!, // 여기서 email은 null이 아님
                  ),
                ),
              );
            } else {
              // email이 null일 때의 처리 로직
              ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text("이메일 정보가 필요합니다. 로그인을 확인해주세요.")));
            }
          },
        ),
        bottom: TabBar(
          controller: _tabController,
          // 탭 컨트롤러 설정
          indicatorColor: Color(0xFFFFE458),
          // 선택된 탭 아래 인디케이터 색상
          labelColor: Colors.black,
          // 선택된 탭 라벨 색상
          unselectedLabelColor: Color(0xFF4E3E36),
          // 선택되지 않은 탭 라벨 색상
          tabs: [
            Tab(icon: Icon(Icons.home, color: Color(0xFF4E3E36),), text: '홈'), // 홈 탭
            Tab(icon: Icon(Icons.help, color: Color(0xFF4E3E36)), text: 'FAQ'), // FAQ 탭
            Tab(icon: Icon(Icons.message, color: Color(0xFF4E3E36)), text: '문의내역'), // 문의내역 탭
            Tab(icon: Icon(Icons.event, color: Color(0xFF4E3E36)), text: '이벤트'), // 고객의 소리 탭
            Tab(icon: Icon(Icons.announcement, color: Color(0xFF4E3E36)), text: '공지사항'), // 공지사항 탭
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController, // 탭 컨트롤러 설정
        children: [
          const ToHomeScreen(),
          // 홈 화면
          const AskedQuestions(),
          // FAQ 화면
          isAdmin ? AdminChatScreen() : UserChatScreen(),
          // 관리자인 경우 AdminChatScreen, 사용자인 경우 UserChatScreen
          EventPage(),
          // 이벤트 화면
          const Announcement(),
          // 공지사항 화면
        ],
      ),
    );
  }
}