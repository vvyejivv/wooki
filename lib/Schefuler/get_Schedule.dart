import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class ScheduleService {
  // Firestore 인스턴스를 초기화합니다.
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // 일정 저장 메서드: 제목, 설명, 날짜 및 유형을 사용하여 Firestore에 일정을 추가합니다.
  Future<void> saveSchedule(
      BuildContext context, // 현재 화면의 컨텍스트
      GlobalKey<FormState> formKey, // 폼의 상태를 관리하는 글로벌 키
      TextEditingController titleController, // 일정 제목 입력 필드 컨트롤러
      TextEditingController descriptionController, // 일정 설명 입력 필드 컨트롤러
      DateTime selectedDate, // 선택된 날짜
      String selectedType, // 선택된 기념일 유형
      Function(DateTime) updateScheduleCount // 일정 개수를 업데이트하는 콜백 함수
      ) async {
    if (formKey.currentState!.validate()) {
      // 폼의 유효성 검사
      formKey.currentState!.save(); // 폼 저장

      try {
        // Firestore에 'schedules' 컬렉션에 일정 추가
        await _firestore.collection('schedules').add({
          'title': titleController.text, // 일정 제목
          'description': descriptionController.text, // 일정 설명
          'date': selectedDate, // 선택된 날짜
          'type': selectedType, // 선택된 기념일 유형
        });

        // 성공 메시지 표시
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('일정이 성공적으로 추가되었습니다.')),
        );
        Navigator.pop(context); // 현재 화면 닫기
        updateScheduleCount(selectedDate); // 일정 개수 업데이트
      } catch (e) {
        print(e); // 에러 로그 출력
        // 실패 메시지 표시
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to add schedule')),
        );
      }
    }
  }

  // 일정 수정 메서드: 주어진 일정 ID와 새 제목, 설명, 날짜 및 유형을 사용하여 Firestore에 저장된 일정을 업데이트합니다.
  Future<void> editSchedule(String id, String title, String description,
      DateTime date, String type) async {
    try {
      // Firestore에서 'schedules' 컬렉션에 해당 ID의 문서를 업데이트
      await _firestore.collection('schedules').doc(id).update({
        'title': title, // 새 제목
        'description': description, // 새 설명
        'date': Timestamp.fromDate(date), // 새 날짜 (Timestamp 형식으로 변환)
        'type': type, // 새 기념일 유형
      });
    } catch (e) {
      print('Failed to update schedule: $e'); // 에러 로그 출력
      throw e; // 에러 발생 시 호출한 곳으로 에러를 던짐
    }
  }

  // 일정 삭제 메서드: 주어진 일정 ID에 해당하는 일정을 Firestore에서 삭제합니다.
  Future<bool> deleteSchedule(String id) async {
    try {
      // Firestore에서 'schedules' 컬렉션에 해당 ID의 문서를 삭제
      await _firestore.collection('schedules').doc(id).delete();
      return true; // 삭제 성공 시 true 반환
    } catch (e) {
      print('Failed to delete schedule: $e'); // 에러 로그 출력
      return false; // 삭제 실패 시 false 반환
    }
  }

  // 선택된 날짜에 해당하는 일정을 Firestore에서 가져오는 메서드
  Future<List<Map<String, dynamic>>> fetchSchedulesForDate(
      DateTime selectedDate) async {
    List<Map<String, dynamic>> schedules = []; // 일정을 저장할 리스트 초기화
    try {
      // Firestore에서 'schedules' 컬렉션의 날짜가 선택된 날짜와 일치하는 문서를 가져옴
      QuerySnapshot querySnapshot = await _firestore
          .collection('schedules')
          .where('date', isEqualTo: Timestamp.fromDate(selectedDate))
          .get();

      // 가져온 문서를 반복하여 데이터 리스트에 추가
      querySnapshot.docs.forEach((doc) {
        final data = doc.data() as Map<String, dynamic>?; // 문서 데이터를 Map 형식으로 변환
        if (data != null) {
          data['documentId'] = doc.id; // 문서 ID를 데이터에 추가
          schedules.add(data); // 데이터 리스트에 추가
        }
      });
      return schedules; // 일정 리스트 반환
    } catch (e) {
      print("Error fetching schedules: $e"); // 에러 로그 출력
      return []; // 에러 발생 시 빈 리스트 반환
    }
  }

  // 선택된 날짜에 해당하는 일정 개수를 업데이트하는 함수입니다.
  Future<Map<String, dynamic>> updateScheduleCount(
      DateTime selectedDate) async {
    try {
      // 선택된 날짜의 일정을 가져옴
      List<Map<String, dynamic>> fetchedSchedules =
          await fetchSchedulesForDate(selectedDate);
      return {
        'schedules': fetchedSchedules, // 일정 리스트
        'scheduleCount': fetchedSchedules.length, // 일정 개수
      };
    } catch (error) {
      print('일정 가져오기 실패: $error'); // 에러 로그 출력
      return {
        'schedules': [], // 빈 리스트 반환
        'scheduleCount': 0, // 일정 개수 0 반환
      };
    }
  }
}
