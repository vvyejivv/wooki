import 'package:flutter/material.dart';
import 'edit_announcement.dart';
import 'firestore_service.dart';

class AnnouncementDetail extends StatefulWidget {
  final AnnouncementData announcement; // 표시할 공지사항 데이터
  final bool isAdmin; // 관리자 여부

  const AnnouncementDetail(
      {Key? key, required this.announcement, required this.isAdmin})
      : super(key: key);

  @override
  _AnnouncementDetailState createState() => _AnnouncementDetailState();
}

class _AnnouncementDetailState extends State<AnnouncementDetail> {
  late FirestoreService _firestoreService; // Firestore 서비스 인스턴스

  @override
  void initState() {
    super.initState();
    _firestoreService = FirestoreService(); // Firestore 서비스 초기화
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('공지사항 상세 정보'), // 앱 바 타이틀
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '제목:', // 제목 라벨
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 8),
            Text(
              widget.announcement.title, // 제목 텍스트
              style: TextStyle(fontSize: 18),
            ),
            SizedBox(height: 16),
            Text(
              '내용:', // 내용 라벨
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 8),
            Text(
              widget.announcement.content, // 내용 텍스트
              style: TextStyle(fontSize: 16),
            ),
            SizedBox(height: 16),
            if (widget.isAdmin) // 관리자인 경우에만 수정 및 삭제 버튼 표시
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  ElevatedButton(
                    onPressed: _deleteAnnouncement, // 삭제 버튼 클릭 시 처리
                    child: const Text('삭제'), // 삭제 버튼 텍스트
                  ),
                  const SizedBox(width: 16),
                  ElevatedButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => EditAnnouncement(
                              announcement: widget
                                  .announcement), // 수정 버튼 클릭 시 EditAnnouncement 위젯으로 이동
                        ),
                      );
                    },
                    child: const Text('수정'), // 수정 버튼 텍스트
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }

  void _deleteAnnouncement() {
    _firestoreService.deleteAnnouncement(widget.announcement.id); // 공지사항 삭제
    Navigator.of(context).pop(); // 현재 화면 닫기
  }
}
