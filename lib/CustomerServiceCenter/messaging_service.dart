import 'package:cloud_firestore/cloud_firestore.dart';

class MessagingService {
  // Firestore 인스턴스를 초기화합니다.
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // 고정된 관리자 ID를 설정합니다.
  final String adminId = 'admin';

  // 메시지를 보내는 메서드입니다.
  Future<void> sendMessage(String senderId, String messageText) async {
    // chatId를 계산합니다. senderId와 adminId를 비교하여 알파벳 순으로 정렬합니다.
    var chatId = (senderId.compareTo(adminId) < 0)
        ? '$senderId-$adminId'
        : '$adminId-$senderId';

    // Firestore의 'messages' 컬렉션 안에 chatId를 문서 ID로 하는 새로운 문서를 생성합니다.
    // 이 문서의 하위 컬렉션 'chats'에 새로운 메시지 문서를 추가합니다.
    await _firestore
        .collection('messages')
        .doc(chatId)
        .collection('chats')
        .add({
      // 메시지 문서에 필요한 필드를 추가합니다.
      'senderId': senderId, // 보낸 사람의 ID
      'receiverId': adminId, // 받는 사람의 ID (고정된 관리자 ID)
      'text': messageText, // 메시지 내용
      'timestamp': FieldValue.serverTimestamp(), // 서버 타임스탬프
    });
  }

  // 실시간 메시지 스트림을 반환하는 메서드입니다.
  Stream<List<Map<String, dynamic>>> getMessageStream(String senderId) {
    // chatId를 계산합니다. senderId와 adminId를 비교하여 알파벳 순으로 정렬합니다.
    var chatId = (senderId.compareTo(adminId) < 0)
        ? '$senderId-$adminId'
        : '$adminId-$senderId';

    // Firestore의 'messages' 컬렉션 안에 chatId를 문서 ID로 하는 문서를 참조합니다.
    // 이 문서의 하위 컬렉션 'chats'에서 실시간으로 데이터를 가져옵니다.
    return _firestore
        .collection('messages')
        .doc(chatId)
        .collection('chats')
        // 'timestamp' 필드로 내림차순 정렬하여 최신 메시지가 먼저 오도록 합니다.
        .orderBy('timestamp', descending: true)
        // snapshots()를 사용하여 컬렉션의 실시간 스트림을 가져옵니다.
        .snapshots()
        // 스트림을 변환하여 각 문서를 Map<String, dynamic>로 변환한 리스트를 반환합니다.
        .map((snapshot) => snapshot.docs
            .map((doc) => doc.data() as Map<String, dynamic>)
            .toList());
  }
}
