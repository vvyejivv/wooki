import 'package:flutter/material.dart';
import 'firestore_service.dart'; // Firestore와 상호 작용하기 위한 서비스 클래스를 임포트합니다.

class EditAnnouncement extends StatefulWidget {
  final AnnouncementData announcement;

  const EditAnnouncement({Key? key, required this.announcement}) : super(key: key);

  @override
  _EditAnnouncementState createState() => _EditAnnouncementState();
}

class _EditAnnouncementState extends State<EditAnnouncement> {
  late TextEditingController _titleController;
  late TextEditingController _contentController;
  late bool _important;
  late FirestoreService _firestoreService;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.announcement.title);
    _contentController = TextEditingController(text: widget.announcement.content);
    _important = widget.announcement.important;
    _firestoreService = FirestoreService();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('공지사항 수정'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextField(
              controller: _titleController,
              decoration: InputDecoration(labelText: '제목'),
            ),
            TextField(
              controller: _contentController,
              decoration: InputDecoration(labelText: '내용'),
            ),
            CheckboxListTile(
              title: Text('긴급공지'),
              value: _important,
              onChanged: (value) {
                setState(() {
                  _important = value!;
                });
              },
            ),
            SizedBox(height: 16),
            Center(
              child: ElevatedButton(
                onPressed: _updateAnnouncement,
                child: Text('수정하기'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _updateAnnouncement() {
    final updatedAnnouncement = AnnouncementData(
      id: widget.announcement.id,
      title: _titleController.text,
      content: _contentController.text,
      date: widget.announcement.date,
      important: _important,
    );
    _firestoreService.updateAnnouncement(updatedAnnouncement);
    Navigator.of(context).pop(); // 수정 페이지 닫기
  }
}
