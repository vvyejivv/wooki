import 'package:flutter/material.dart';
import 'package:wooki/CustomerServiceCenter/user_chat_screen.dart';
import 'admin_chat_screen.dart';
import 'announcement.dart';
import 'asked_questions.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'firestore_service.dart';


class MainScreens extends StatefulWidget {
  const MainScreens({Key? key}) : super(key: key);

  @override
  State<MainScreens> createState() => _MainScreensState();
}

class _MainScreensState extends State<MainScreens> with SingleTickerProviderStateMixin {
  late final TabController _tabController;
  late SharedPreferences prefs;
  String? email;
  bool isAdmin = false;
  late FirestoreService firestoreService;

  @override
  void initState() {
    super.initState();
    firestoreService = FirestoreService();
    _tabController = TabController(length: 5, vsync: this);
    _loadSessionData();
  }

  Future<void> _loadSessionData() async {
    prefs = await SharedPreferences.getInstance();
    String? userEmail = prefs.getString('email');
    if (userEmail != null) {
      bool adminStatus = await firestoreService.isAdminByEmail(userEmail);
      setState(() {
        email = userEmail;
        isAdmin = adminStatus;
      });
    }
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
          isAdmin ? AdminChatScreen() : UserChatScreen(),
          const Center(child: Text('Customer Voice Page')),
          const Announcement(),
        ],
      ),
    );
  }
}
