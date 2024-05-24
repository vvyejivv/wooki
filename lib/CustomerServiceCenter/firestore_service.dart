import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class FirestoreService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // Firestore에서 'No' 기준으로 모든 FAQ를 가져오는 메소드
  Stream<List<FAQ>> getFAQs() {
    return _db
        .collection('faqs')
        .orderBy('No', descending: false) // 'No' 필드를 기준으로 오름차순 정렬
        .snapshots()
        .map((snapshot) =>
            snapshot.docs.map((doc) => FAQ.fromFirestore(doc.data())).toList());
  }

  // 카테고리별로 Firestore에서 FAQ를 가져오는 메소드
  Stream<List<FAQ>> getFAQsByCategory(String category) {
    return _db
        .collection('faqs')
        .where('category', isEqualTo: category) // 'category' 필드를 기준으로 필터링
        .orderBy('No', descending: false) // 그 다음 'No' 필드를 기준으로 오름차순 정렬
        .snapshots()
        .map((snapshot) =>
            snapshot.docs.map((doc) => FAQ.fromFirestore(doc.data())).toList());
  }

  // Firestore에서 모든 공지사항을 가져오는 메소드
  Stream<List<AnnouncementData>> getAnnouncements() {
    return _db.collection('announcements')
        .orderBy('date', descending: true)
        .snapshots()
        .map((snapshot) =>
        snapshot.docs.map((doc) => AnnouncementData.fromFirestore(doc.data())).toList());
  }

  // Firestore에서 사용자가 관리자인지 확인하는 메소드
  Future<bool> isAdmin(String userId) async {
    var doc = await _db.collection('users').doc(userId).get();
    return doc.exists && doc.data()?['isAdmin'] == true;
  }

  // Firestore에 새로운 공지사항을 추가하는 메소드
  Future<void> addAnnouncement(AnnouncementData announcement) {
    return _db.collection('announcements').add(announcement.toFirestore());
  }
}

class AnnouncementData {
  final String id;
  final String title;
  final String content;
  final DateTime date;
  final bool important;

  AnnouncementData({
    required this.id,
    required this.title,
    required this.content,
    required this.date,
    required this.important,
  });

  factory AnnouncementData.fromFirestore(Map<String, dynamic> firestore) {
    return AnnouncementData(
      id: firestore['id'] as String,
      title: firestore['title'] as String,
      content: firestore['content'] as String,
      date: (firestore['date'] as Timestamp).toDate(),
      important: firestore['important'] as bool,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'id': id,
      'title': title,
      'content': content,
      'date': date,
      'important': important,
    };
  }
}

class FAQ {
  final String no;
  final String category;
  final String question;
  final String answer;

  FAQ(
      {required this.no,
      required this.question,
      required this.answer,
      required this.category});

  // Firestore 문서 데이터를 FAQ 객체로 변환하는 팩토리 생성자
  factory FAQ.fromFirestore(Map<String, dynamic> firestore) {
    return FAQ(
      no: firestore['No'] as String,
      category: firestore['category'] as String,
      question: firestore['question'] as String,
      answer: firestore['answer'] as String,
    );
  }
}
