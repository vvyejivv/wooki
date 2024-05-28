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
  bool isAdmin = false;

  @override
  void initState() {
    super.initState();
    _loadSessionData();
  }

  Future<void> _loadSessionData() async {
    final prefs = await SharedPreferences.getInstance();
    String? email = prefs.getString('email');
    if (email != null) {
      bool adminStatus = await _firestoreService.isAdminByEmail(email);
      setState(() {
        isAdmin = adminStatus;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('공지사항'),
        centerTitle: true,
        backgroundColor: Colors.blueAccent,
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              child: StreamBuilder<List<AnnouncementData>>(
                stream: _firestoreService.getAnnouncements(),
                builder: (context, snapshot) {
                  if (snapshot.hasError) {
                    return Center(
                      child: Text('데이터를 불러오는 중 오류가 발생했습니다.'),
                    );
                  }
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return Center(
                      child: CircularProgressIndicator(),
                    );
                  }
                  return ListView.builder(
                    shrinkWrap: true,
                    physics: NeverScrollableScrollPhysics(),
                    itemCount: snapshot.data?.length ?? 0,
                    itemBuilder: (context, index) {
                      var announcement = snapshot.data![index];
                      String truncatedContent = announcement.content.length > 10
                          ? '${announcement.content.substring(0, 10)}...'
                          : announcement.content;
                      return Card(
                        elevation: 4,
                        margin: const EdgeInsets.all(8),
                        child: ListTile(
                          leading: Icon(
                            announcement.important
                                ? Icons.campaign
                                : Icons.notifications_none,
                            color: Colors.blue,
                          ),
                          title: Text(
                            announcement.title,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          subtitle: Text(truncatedContent),
                          trailing:
                          const Icon(Icons.arrow_forward_ios, size: 16),
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => AnnouncementDetail(
                                  announcement: announcement,
                                  isAdmin: isAdmin, // isAdmin 파라미터를 제공합니다.
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
      floatingActionButton: isAdmin
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
    bool _important = false;

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
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
                _firestoreService.addAnnouncement(newAnnouncement);
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }
}
