import 'package:flutter/material.dart';
import 'package:wooki/star/Schefuler/get_Schedul.dart'; // ScheduleService 클래스가 있는 파일 경로를 지정하세요.

// 일정 목록을 새로고침하는 메서드


// 일정 삭제 메서드
void deleteSchedule(BuildContext context, DateTime selectedDate, List<Map<String, dynamic>> schedules, int index) {
  String documentId = schedules[index]['documentId']; // 삭제할 일정의 문서 ID
  showDialog(
    context: context,
    builder: (BuildContext context) {
      return AlertDialog(
        title: Text('일정 삭제'),
        content: Text('이 일정을 삭제하시겠습니까?'),
        actions: [
          // "확인" 버튼
          TextButton(
            onPressed: () {
              // 일정 삭제 로직을 수행합니다.
              ScheduleService().deleteSchedule(documentId).then((_) {
                // 삭제가 성공하면 화면을 갱신합니다.
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('일정이 삭제되었습니다.')),
                );
                // 삭제가 완료되면 화면을 갱신합니다.
               // updateScheduleCount(selectedDate);
              }).catchError((error) {
                // 삭제 중 에러가 발생한 경우 처리합니다.
                print('일정 삭제 실패: $error');
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('일정 삭제에 실패했습니다.')),
                );
              }).whenComplete(() {
                // 삭제가 완료되면 대화 상자를 닫습니다.
                Navigator.of(context).pop();
              });
            },
            child: Text('확인'),
          ),
          // "취소" 버튼
          TextButton(
            onPressed: () {
              // 취소 버튼을 누르면 대화 상자를 닫습니다.
              Navigator.of(context).pop();
            },
            child: Text('취소'),
          ),
        ],
      );
    },
  );
}
