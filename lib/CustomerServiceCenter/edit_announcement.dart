import 'package:flutter/material.dart';
import 'firestore_service.dart'; // Firestore와 상호 작용하기 위한 서비스 클래스를 임포트합니다.

class EditAnnouncement extends StatefulWidget {
  final AnnouncementData announcement; // 수정할 공지사항 데이터

  const EditAnnouncement({Key? key, required this.announcement})
      : super(key: key);

  @override
  _EditAnnouncementState createState() => _EditAnnouncementState();
}

class _EditAnnouncementState extends State<EditAnnouncement> {
  late TextEditingController _titleController; // 제목 입력 필드 컨트롤러
  late TextEditingController _contentController; // 내용 입력 필드 컨트롤러
  late bool _important; // 긴급 공지 여부
  late FirestoreService _firestoreService; // Firestore 서비스 인스턴스

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(
        text: widget.announcement.title); // 제목 입력 필드 컨트롤러 초기화
    _contentController = TextEditingController(
        text: widget.announcement.content); // 내용 입력 필드 컨트롤러 초기화
    _important = widget.announcement.important; // 긴급 공지 여부 초기화
    _firestoreService = FirestoreService(); // Firestore 서비스 초기화
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('공지사항 수정'), // 앱 바 타이틀
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextField(
              controller: _titleController, // 제목 입력 필드에 컨트롤러 연결
              decoration: InputDecoration(labelText: '제목'), // 제목 입력 필드 레이블
            ),
            TextField(
              controller: _contentController, // 내용 입력 필드에 컨트롤러 연결
              decoration: InputDecoration(labelText: '내용'), // 내용 입력 필드 레이블
            ),
            CheckboxListTile(
              title: Text('긴급공지'), // 체크박스 라벨
              value: _important, // 체크 상태
              onChanged: (value) {
                setState(() {
                  _important = value!; // 체크 상태 업데이트
                });
              },
            ),
            SizedBox(height: 16),
            Center(
              child: ElevatedButton(
                onPressed: _updateAnnouncement, // 수정하기 버튼 클릭 시 처리
                child: Text('수정하기'), // 버튼 텍스트
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
      // 업데이트된 제목
      content: _contentController.text,
      // 업데이트된 내용
      date: widget.announcement.date,
      important: _important, // 업데이트된 긴급 공지 여부
    );
    _firestoreService.updateAnnouncement(updatedAnnouncement); // 공지사항 업데이트
    Navigator.of(context).pop(); // 수정 페이지 닫기
  }
}