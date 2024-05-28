import 'package:flutter/material.dart';
import 'firestore_service.dart';
import 'edit_announcement.dart';

class AnnouncementDetail extends StatefulWidget {
  final AnnouncementData announcement;
  final bool isAdmin;

  const AnnouncementDetail({Key? key, required this.announcement, required this.isAdmin})
      : super(key: key);

  @override
  _AnnouncementDetailState createState() => _AnnouncementDetailState();
}

class _AnnouncementDetailState extends State<AnnouncementDetail> {
  late FirestoreService _firestoreService;

  @override
  void initState() {
    super.initState();
    _firestoreService = FirestoreService();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('공지사항 상세 정보'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '제목:',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 8),
            Text(
              widget.announcement.title,
              style: TextStyle(fontSize: 18),
            ),
            SizedBox(height: 16),
            Text(
              '내용:',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 8),
            Text(
              widget.announcement.content,
              style: TextStyle(fontSize: 16),
            ),
            SizedBox(height: 16),
            if (widget.isAdmin)
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  ElevatedButton(
                    onPressed: _deleteAnnouncement,
                    child: const Text('삭제'),
                  ),
                  const SizedBox(width: 16),
                  ElevatedButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => EditAnnouncement(announcement: widget.announcement),
                        ),
                      );
                    },
                    child: const Text('수정'),
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }

  void _deleteAnnouncement() {
    _firestoreService.deleteAnnouncement(widget.announcement.id);
    print(widget.announcement.id);
    Navigator.of(context).pop();
  }
}
