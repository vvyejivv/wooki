import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../login/Session.dart';
import 'announcement.dart';
import 'asked_questions.dart';
import 'chat_screen.dart';
import 'admin_chat_screen.dart';

class MainScreens extends StatefulWidget {
  const MainScreens({super.key});

  @override
  State<MainScreens> createState() => _MainScreensState();
}

class _MainScreensState extends State<MainScreens> with SingleTickerProviderStateMixin {
  late final TabController _tabController;

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
    var session = Provider.of<Session>(context);
    //bool isAdmin = session.isAdmin; // Session에서 관리자인지 여부를 가져옵니다.

    return Scaffold(
      appBar: AppBar(
        title: const Text('고객센터'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.black),
          onPressed: () => Navigator.of(context).pop(),
        ),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.blue,
          labelColor: Colors.black,
          unselectedLabelColor: Colors.grey,
          tabs: [
            Tab(icon: Icon(Icons.home), text: '홈'),
            Tab(icon: Icon(Icons.help), text: 'FAQ'),
            Tab(icon: Icon(Icons.message), text: '문의내역'),
            Tab(icon: Icon(Icons.record_voice_over), text: '고객의 소리'),
            Tab(icon: Icon(Icons.announcement), text: '공지사항'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          const Center(child: Text('Home Page')),
          const AskedQuestions(),
          //isAdmin ? AdminChatScreen() : ChatScreen(), // 관리자인 경우 AdminChatScreen, 일반 사용자인 경우 ChatScreen
          const Center(child: Text('Customer Voice Page')),
          const Announcement(),
        ],
      ),
    );
  }
}
