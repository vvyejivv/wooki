import 'package:flutter/material.dart';
import 'package:wooki/CustomerServiceCenter/announcement.dart';
import 'asked_questions.dart';
import '../login/Session.dart'; // Session 클래스 임포트

class MainScreens extends StatefulWidget {
  const MainScreens({super.key});

  @override
  State<MainScreens> createState() => _MainScreensState();
}

class _MainScreensState extends State<MainScreens> with SingleTickerProviderStateMixin {
  late final TabController _tabController; // final로 선언하여 초기화 후 변경되지 않음을 명시

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 5, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('고객센터'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.black),
          onPressed: () => Navigator.of(context).pop(),
        ),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: '홈'),
            Tab(text: 'FAQ'),
            Tab(text: '문의내역'),
            Tab(text: '고객의 소리'),
            Tab(text: '공지사항'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: const [
          Center(child: Text('Home Page')),
          AskedQuestions(), // FAQ 페이지로 `AskedQuestions` 위젯 사용
          Center(child: Text('Inquiry History Page')),
          Center(child: Text('Customer Voice Page')),
          Announcement(),
        ],
      ),
    );
  }
}
