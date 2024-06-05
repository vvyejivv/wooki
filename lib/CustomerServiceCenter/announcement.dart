import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'detail_announcement.dart';
import 'firestore_service.dart'; // Firestore와 상호 작용하기 위한 서비스 클래스를 임포트합니다.

class Announcement extends StatefulWidget {
  const Announcement({Key? key}) : super(key: key);

  @override
  _AnnouncementState createState() => _AnnouncementState();
}

class _AnnouncementState extends State<Announcement> {
  final FirestoreService _firestoreService = FirestoreService();
  bool isAdmin = false; // 관리자 여부를 저장하는 변수

  @override
  void initState() {
    super.initState();
    _loadSessionData(); // 세션 데이터를 로드하는 함수 호출
  }

  Future<void> _loadSessionData() async {
    final prefs = await SharedPreferences.getInstance();
    String? email = prefs.getString('email'); // SharedPreferences에서 이메일을 가져옵니다.
    if (email != null) {
      bool adminStatus = await _firestoreService
          .isAdminByEmail(email); // Firestore에서 관리자 여부를 확인합니다.
      setState(() {
        isAdmin = adminStatus; // 관리자 여부를 상태에 저장합니다.
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFFFFFDEF),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              child: StreamBuilder<List<AnnouncementData>>(
                stream: _firestoreService.getAnnouncements(),
                // 공지사항 데이터를 가져오는 스트림
                builder: (context, snapshot) {
                  if (snapshot.hasError) {
                    return Center(
                      child: Text('데이터를 불러오는 중 오류가 발생했습니다.'), // 데이터 로드 오류 메시지
                    );
                  }
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return Center(
                      child: CircularProgressIndicator(), // 데이터 로딩 중 로딩 인디케이터
                    );
                  }
                  return ListView.builder(
                    shrinkWrap: true,
                    physics: NeverScrollableScrollPhysics(),
                    itemCount: snapshot.data?.length ?? 0,
                    // 공지사항 수만큼 리스트 아이템 생성
                    itemBuilder: (context, index) {
                      var announcement = snapshot.data![index];
                      String truncatedContent = announcement.content.length > 10
                          ? '${announcement.content.substring(0, 10)}...' // 공지사항 내용이 너무 길 경우 일부만 표시
                          : announcement.content;
                      return Card(
                        color: Color(0xFF4E3E36),
                        elevation: 4,
                        margin: const EdgeInsets.all(8),
                        child: ListTile(
                          leading: Icon(
                            announcement.important
                                ? Icons.campaign // 중요 공지면 아이콘 변경
                                : Icons.notifications_none,
                            color: Colors.blue,
                          ),
                          title: Text(
                            announcement.title,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Colors.white
                            ),
                          ),
                          subtitle: Text(
                              truncatedContent,
                              style: TextStyle(
                                  color: Colors.white
                              ),
                          ),
                          trailing:
                              const Icon(Icons.arrow_forward_ios, size: 16),
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => AnnouncementDetail(
                                  announcement: announcement,
                                  isAdmin: isAdmin, // 공지사항 상세 화면으로 이동
                                ),
                              ),
                            );
                          },
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ),
        ],
      ),
      floatingActionButton: isAdmin // 관리자인 경우에만 추가 버튼 표시
          ? FloatingActionButton(
              onPressed: _showAddAnnouncementDialog,
              child: Icon(Icons.add),
              backgroundColor: Colors.blueAccent,
            )
          : null,
    );
  }

  void _showAddAnnouncementDialog() {
    final _titleController = TextEditingController();
    final _contentController = TextEditingController();
    bool _important = false; // 새 공지사항의 중요 여부

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: Color(0xFFFFFDEF),
          title: const Text('새 공지사항 추가'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: _titleController,
                decoration: const InputDecoration(labelText: '제목'),
              ),
              TextField(
                controller: _contentController,
                decoration: const InputDecoration(labelText: '내용'),
              ),
              CheckboxListTile(
                title: const Text('중요 공지'),
                value: _important,
                onChanged: (value) {
                  setState(() {
                    _important = value!;
                  });
                },
              ),
            ],
          ),
          actions: [
            TextButton(
              child: const Text('취소'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              child: const Text('추가'),
              onPressed: () {
                final newAnnouncement = AnnouncementData(
                  id: DateTime.now().toString(),
                  title: _titleController.text,
                  content: _contentController.text,
                  date: DateTime.now(),
                  important: _important,
                );
                _firestoreService
                    .addAnnouncement(newAnnouncement); // Firestore에 새 공지사항 추가
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }
}
