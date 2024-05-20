import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class EditScheduleScreen extends StatefulWidget {
  final Map<String, dynamic> schedule; // 수정할 일정 정보를 저장하는 맵
  final String documentId; // 수정할 일정의 문서 ID

  const EditScheduleScreen({Key? key, required this.schedule, required this.documentId}) : super(key: key);

  @override
  _EditScheduleScreenState createState() => _EditScheduleScreenState();
}

class _EditScheduleScreenState extends State<EditScheduleScreen> {
  late TextEditingController _titleController; // 제목을 입력받는 텍스트 필드 컨트롤러
  late TextEditingController _descriptionController; // 내용을 입력받는 텍스트 필드 컨트롤러

  @override
  void initState() {
    super.initState();
    // 수정할 일정의 제목과 내용으로 텍스트 필드 컨트롤러 초기화
    if (widget.schedule != null && widget.schedule['title'] != null) {
      _titleController = TextEditingController(text: widget.schedule['title']);
    }
    if (widget.schedule != null && widget.schedule['description'] != null) {
      _descriptionController = TextEditingController(text: widget.schedule['description']);
    }
  }


  // 일정 업데이트 함수
  Future<void> _updateSchedule(String updatedTitle, String updatedDescription) async {
    try {
      if (updatedTitle != null && updatedDescription != null) {
        // Firestore 컬렉션에서 해당 문서를 찾아 업데이트
        await FirebaseFirestore.instance.collection('schedules').doc(widget.documentId).update({
          'title': updatedTitle, // 제목 업데이트
          'description': updatedDescription, // 내용 업데이트
          // 추가적인 필드가 있다면 여기에 추가할 수 있습니다.
        });
        // 업데이트 성공 시 메시지 출력
        print('Schedule updated successfully');
      } else {
        // 수정된 정보가 null이면 업데이트하지 않음
        print('Updated title or description is null. Not updating schedule.');
      }
    } catch (error) {
      // 업데이트 실패 시 에러 처리
      print('Failed to update schedule: $error');
    }
  }



  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Edit Schedule'),
      ),
      body: Padding(
        padding: EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextField(
              controller: _titleController,
              decoration: InputDecoration(labelText: 'Title'),
            ),
            SizedBox(height: 16.0),
            TextField(
              controller: _descriptionController,
              decoration: InputDecoration(labelText: 'Description'),
            ),
            SizedBox(height: 16.0),
            ElevatedButton(
              onPressed: () {
                // 수정된 정보 저장하기
                String updatedTitle = _titleController.text;
                String updatedDescription = _descriptionController.text;
                // 일정 업데이트 함수 호출
                _updateSchedule(updatedTitle, updatedDescription);
                // 수정 완료 후 화면 닫기
                Navigator.pop(context);
              },
              child: Text('Save'),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    // 사용한 텍스트 필드 컨트롤러들을 해제하여 메모리 누수 방지
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }
}
