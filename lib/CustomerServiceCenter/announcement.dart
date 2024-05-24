import 'package:firebase_auth/firebase_auth.dart' as firebase_auth; // Firebase Auth 패키지 임포트
import 'package:flutter/material.dart';
import 'firestore_service.dart';
import 'package:provider/provider.dart'; // Provider 패키지 임포트
import '../login/Session.dart'; // Session 클래스 임포트

// 공지사항 위젯 클래스
class Announcement extends StatefulWidget {
  const Announcement({super.key});

  @override
  State<Announcement> createState() => _AnnouncementState();
}

// 공지사항 위젯 상태 클래스
class _AnnouncementState extends State<Announcement> {
  final FirestoreService _firestoreService = FirestoreService(); // FirestoreService 인스턴스 생성
  bool isAdmin = false; // 관리자 여부를 저장하는 변수

  @override
  void initState() {
    super.initState();
    _checkAdmin(); // initState에서 관리자 여부 확인 메소드 호출
  }

  // 관리자 여부를 확인하는 비동기 메소드
  Future<bool> _checkAdmin() async {
    firebase_auth.User? user = firebase_auth.FirebaseAuth.instance.currentUser;
    if (user != null) {
      bool adminStatus = await _firestoreService.isAdmin(user.uid); // FirestoreService를 통해 관리자 여부 확인
      setState(() {
        isAdmin = adminStatus; // 관리자 여부 변수 업데이트
      });
      return adminStatus; // 관리자 여부 반환
    }
    return false;
  }

  // 화면 빌드하는 메소드
  @override
  Widget build(BuildContext context) {
    var session = Provider.of<Session>(context); // Provider를 통해 세션 정보 가져오기
    var user = session.user; // 세션에서 사용자 정보 가져오기

    return Scaffold(
      appBar: AppBar(
        title: const Text('공지사항'), // 앱바 타이틀 설정
        centerTitle: true, // 타이틀 가운데 정렬
        backgroundColor: Colors.blueAccent, // 앱바 배경색 설정
        actions: [
          if (isAdmin) // 관리자인 경우에만 버튼 표시
            IconButton(
              icon: const Icon(Icons.add),
              onPressed: () {
                _showAddAnnouncementDialog(); // 공지사항 추가 다이얼로그 표시 메소드 호출
              },
            ),
        ],
      ),
      body: Column(
        children: [
          if (user != null) Text('안녕하세요, ${user.getUsername}님'), // 사용자 정보 표시
          if (user != null) Text('이메일: ${user.getEmail}'), // 사용자 이메일 표시
          if (user != null) Text('전화번호: ${user.getPhone}'), // 사용자 전화번호 표시
          Expanded(
            child: StreamBuilder<List<AnnouncementData>>(
              stream: _firestoreService.getAnnouncements(), // 공지사항 데이터 가져오는 스트림
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return const Center(
                    child: Text('데이터를 불러오는 중 오류가 발생했습니다.'), // 데이터 불러오는 중 오류 발생 시 텍스트 표시
                  );
                }
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator()); // 데이터 불러오는 중 로딩 인디케이터 표시
                }
                return ListView.builder(
                  itemCount: snapshot.data?.length ?? 0, // 공지사항 개수만큼 리스트 아이템 빌드
                  itemBuilder: (context, index) {
                    var announcement = snapshot.data![index];
                    String truncatedContent = announcement.content.length > 10
                        ? '${announcement.content.substring(0, 10)}...' // 공지사항 내용이 너무 길면 일부만 표시
                        : announcement.content;
                    return Card(
                      elevation: 4, // 카드 그림자 설정
                      margin: const EdgeInsets.all(8), // 카드 간격 설정
                      child: ListTile(
                        leading: Icon(
                          announcement.important ? Icons.campaign : Icons.notifications_none, // 중요 공지 여부에 따라 아이콘 설정
                          color: Colors.blue, // 아이콘 색상 설정
                        ),
                        title: Text(
                          announcement.title,
                          style: const TextStyle(fontWeight: FontWeight.bold), // 공지사항 제목 설정
                        ),
                        subtitle: Text(truncatedContent), // 공지사항 내용 설정
                        trailing: const Icon(Icons.arrow_forward_ios, size: 16), // 우측 화살표 아이콘 설정
                        onTap: () {
                          showDialog(
                            context: context,
                            builder: (context) => AlertDialog(
                              title: Text(announcement.title), // 다이얼로그 제목 설정
                              content: Text(announcement.content), // 다이얼로그 내용 설정
                              actions: [
                                TextButton(
                                  child: const Text('닫기'), // 닫기 버튼 텍스트 설정
                                  onPressed: () => Navigator.of(context).pop(), // 다이얼로그 닫기
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  // 공지사항 추가 다이얼로그 표시 메소드
  void _showAddAnnouncementDialog() {
    final _titleController = TextEditingController();
    final _contentController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) {
        bool _important = false;
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: const Text('새 공지사항 추가'), // 다이얼로그 제목 설정
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: _titleController,
                    decoration: const InputDecoration(labelText: '제목'), // 제목 입력 필드 설정
                  ),
                  TextField(
                    controller: _contentController,
                    decoration: const InputDecoration(labelText: '내용'), // 내용 입력 필드 설정
                  ),
                  CheckboxListTile(
                    title: const Text('중요 공지'), // 체크박스 타이틀 설정
                    value: _important,
                    onChanged: (value) {
                      setState(() {
                        _important = value!;
                      });
                    },
                  ),
                ],
              ),
              actions: [
                TextButton(
                  child: const Text('취소'), // 취소 버튼 텍스트 설정
                  onPressed: () {
                    Navigator.of(context).pop(); // 다이얼로그 닫기
                  },
                ),
                TextButton(
                  child: const Text('추가'), // 추가 버튼 텍스트 설정
                  onPressed: () {
                    final newAnnouncement = AnnouncementData(
                      id: DateTime.now().toString(),
                      title: _titleController.text,
                      content: _contentController.text,
                      date: DateTime.now(),
                      important: _important,
                    );
                    _firestoreService.addAnnouncement(newAnnouncement); // 공지사항 추가 메소드 호출
                    Navigator.of(context).pop(); // 다이얼로그 닫기
                  },
                ),
              ],
            );
          },
        );
      },
    );
  }
}
