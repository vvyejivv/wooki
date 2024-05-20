import 'package:cloud_firestore/cloud_firestore.dart';

class ScheduleService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // 선택된 날짜에 해당하는 일정을 Firestore에서 가져오는 메서드
  Future<List<Map<String, dynamic>>> fetchSchedulesForDate(DateTime selectedDate) async {
    List<Map<String, dynamic>> schedules = [];

    try {
      QuerySnapshot querySnapshot = await _firestore
          .collection('schedules')
          .where('date', isEqualTo: selectedDate)
          .get();

      querySnapshot.docs.forEach((doc) {
        final data = doc.data() as Map<String, dynamic>?; // 타입 변환
        if (data != null) {
          schedules.add(data);
        }
      });
      return schedules;
    } catch (e) {
      print("Error fetching schedules: $e");
      return [];
    }
  }
}
