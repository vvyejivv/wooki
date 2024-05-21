import 'package:cloud_firestore/cloud_firestore.dart';

class ScheduleService {
  // Firestore 인스턴스를 초기화합니다.
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // 일정 업데이트 메서드: 주어진 일정 ID와 새 제목 및 설명을 사용하여 일정을 업데이트합니다.
  Future<void> updateSchedule(String id, String title, String description,  DateTime date) async {
    try {
      // 일정 컬렉션에서 주어진 ID에 해당하는 문서를 업데이트합니다.
      await _firestore.collection('schedules').doc(id).update({
        'title': title,
        'description': description,
        'date': Timestamp.fromDate(date), // 날짜를 Timestamp 형식으로 저장
      });
    } catch (e) {
      // 에러 발생 시 콘솔에 에러 메시지를 출력하고, 예외를 던집니다.
      print('Failed to update schedule: $e');
      throw e;
    }
  }

  // 일정 삭제 메서드: 주어진 일정 ID에 해당하는 일정을 Firestore에서 삭제합니다.
  Future<void> deleteSchedule(String id) async {
    try {
      // 일정 컬렉션에서 주어진 ID에 해당하는 문서를 삭제합니다.
      await _firestore.collection('schedules').doc(id).delete();
    } catch (e) {
      // 에러 발생 시 콘솔에 에러 메시지를 출력하고, 예외를 던집니다.
      print('Failed to delete schedule: $e');
      throw e;
    }
  }

  // 선택된 날짜에 해당하는 일정을 Firestore에서 가져오는 메서드
  Future<List<Map<String, dynamic>>> fetchSchedulesForDate(DateTime selectedDate) async {
    // 일정 데이터를 저장할 리스트를 초기화합니다.
    List<Map<String, dynamic>> schedules = [];

    try {
      // 일정 컬렉션에서 'date' 필드가 선택된 날짜와 일치하는 문서를 가져옵니다.
      QuerySnapshot querySnapshot = await _firestore
          .collection('schedules')
          .where('date', isEqualTo: selectedDate)
          .get();

      // 가져온 문서 각각에 대해 반복합니다.
      querySnapshot.docs.forEach((doc) {
        // 문서 데이터를 Map 형태로 변환합니다.
        final data = doc.data() as Map<String, dynamic>?; // 타입 변환
        if (data != null) {
          // 문서 ID를 데이터에 추가합니다.
          data['documentId'] = doc.id;
          // 일정 리스트에 추가합니다.
          schedules.add(data);
        }
      });
      // 일정 리스트를 반환합니다.
      return schedules;
    } catch (e) {
      // 에러 발생 시 콘솔에 에러 메시지를 출력하고, 빈 리스트를 반환합니다.
      print("Error fetching schedules: $e");
      return [];
    }
  }
}
