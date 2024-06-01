import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_auth/firebase_auth.dart';

// Firebase와 상호 작용하는 서비스 클래스 정의
class FirestoreService {
  final FirebaseFirestore _db = FirebaseFirestore.instance; // Firestore 인스턴스 생성
  late SharedPreferences prefs; // SharedPreferences 변수 선언

  // 이메일을 기반으로 사용자가 관리자인지 확인하는 메소드
  Future<bool> isAdminByEmail(String email) async {
    var querySnapshot = await _db
        .collection('USERLIST')
        .where('email', isEqualTo: email)
        .get(); // 이메일을 기준으로 쿼리 실행
    return querySnapshot.docs.isNotEmpty &&
        querySnapshot.docs.first.get('isAdmin'); // 결과 반환
  }

  // SharedPreferences 초기화 메소드
  Future<Map<String, dynamic>> initPrefs() async {
    prefs = await SharedPreferences.getInstance(); // SharedPreferences 초기화
    final email = prefs.getString('email'); // 이메일 가져오기
    final isAdmin = prefs.getBool('isAdmin') ?? false; // 관리자 여부 가져오기
    return {'email': email, 'isAdmin': isAdmin}; // 이메일과 관리자 여부 반환
  }

  // Firestore에서 모든 FAQ 가져오기
  Stream<List<FAQ>> getFAQs() {
    return _db
        .collection('faqs')
        .orderBy('No', descending: false) // 'No' 필드를 기준으로 오름차순 정렬
        .snapshots() // 스트림 반환
        .map((snapshot) => snapshot.docs
            .map((doc) => FAQ.fromFirestore(doc.data()))
            .toList()); // 스트림 요소 변환하여 반환
  }

  // 카테고리별로 Firestore에서 FAQ 가져오기
  Stream<List<FAQ>> getFAQsByCategory(String category) {
    return _db
        .collection('faqs')
        .where('category', isEqualTo: category) // 'category' 필드로 필터링
        .orderBy('No', descending: false) // 'No' 필드를 기준으로 오름차순 정렬
        .snapshots() // 스트림 반환
        .map((snapshot) => snapshot.docs
            .map((doc) => FAQ.fromFirestore(doc.data()))
            .toList()); // 스트림 요소 변환하여 반환
  }

  // Firestore에서 모든 공지사항 가져오기
  Stream<List<AnnouncementData>> getAnnouncements() {
    return _db
        .collection('announcements')
        .orderBy('date', descending: true) // 'date' 필드를 기준으로 내림차순 정렬
        .snapshots() // 스트림 반환
        .map((snapshot) => snapshot.docs
            .map((doc) => AnnouncementData.fromFirestore(doc.data(), doc.id))
            .toList()); // 스트림 요소 변환하여 반환
  }

  // Firestore에 새로운 공지사항 추가하는 메소드
  Future<void> addAnnouncement(AnnouncementData announcement) {
    return _db
        .collection('announcements')
        .add(announcement.toFirestore()); // 새로운 공지사항 추가
  }

  // 공지사항 수정 메소드
  Future<void> updateAnnouncement(AnnouncementData updatedAnnouncement) async {
    await _db
        .collection('announcements')
        .doc(updatedAnnouncement.id)
        .update(updatedAnnouncement.toFirestore()); // 공지사항 수정
  }

  // 공지사항 삭제 메소드
  Future<void> deleteAnnouncement(String announcementId) async {
    await _db.collection('announcements').doc(announcementId).delete();
  }
}

// 공지사항 데이터 모델 클래스 정의
class AnnouncementData {
  final String id; // 수정이 필요한 부분: id 필드 추가

  final String title;
  final String content;
  final DateTime date;
  final bool important;

  AnnouncementData({
    required this.id, // 수정이 필요한 부분: id 필드 추가
    required this.title,
    required this.content,
    required this.date,
    required this.important,
  });

  // Firestore 문서에서 데이터를 가져와 공지사항 데이터 객체로 변환하는 팩토리 생성자
  factory AnnouncementData.fromFirestore(
      Map<String, dynamic> firestore, String id) {
    return AnnouncementData(
      id: id,
      // 수정이 필요한 부분: Firestore 문서에서 id 필드를 가져와서 설정
      title: firestore['title'] as String,
      content: firestore['content'] as String,
      date: (firestore['date'] as Timestamp).toDate(),
      // Timestamp를 DateTime으로 변환
      important: firestore['important'] as bool,
    );
  }

  // 공지사항 데이터를 Firestore 문서에 맞게 변환하는 메소드
  Map<String, dynamic> toFirestore() {
    return {
      'title': title,
      'content': content,
      'date': date,
      'important': important,
    };
  }
}

// FAQ 데이터 모델 클래스 정의
class FAQ {
  final String no;
  final String category;
  final String question;
  final String answer;

  FAQ({
    required this.no,
    required this.question,
    required this.answer,
    required this.category,
  });

  // Firestore 문서에서 데이터를 가져와 FAQ 객체로 변환하는 팩토리 생성자
  factory FAQ.fromFirestore(Map<String, dynamic> firestore) {
    return FAQ(
      no: firestore['No'] as String,
      category: firestore['category'] as String,
      question: firestore['question'] as String,
      answer: firestore['answer'] as String,
    );
  }
}
