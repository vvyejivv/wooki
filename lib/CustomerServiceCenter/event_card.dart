import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'edit_event_page.dart';

class EventCard extends StatelessWidget {
  final DocumentSnapshot event;
  final bool isAdmin;

  // EventCard 위젯을 생성할 때 필요한 event와 isAdmin 매개변수를 받습니다.
  const EventCard({required this.event, required this.isAdmin});

  @override
  Widget build(BuildContext context) {
    // 이벤트 정보를 표시하는 Card 위젯을 반환합니다.
    return Card(
      elevation: 4, // 그림자의 높이를 설정합니다.
      margin: EdgeInsets.symmetric(vertical: 8, horizontal: 16), // 카드의 여백을 설정합니다.
      shape: RoundedRectangleBorder( // 카드의 모서리를 둥글게 만듭니다.
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell( // 카드를 탭할 때마다 이벤트 편집 페이지로 이동합니다.
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) =>
                  EditEventPage(event: event, isAdmin: isAdmin), // 이벤트 편집 페이지로 이동합니다.
            ),
          );
        },
        child: Padding(
          padding: const EdgeInsets.all(16.0), // 카드 내부의 패딩을 설정합니다.
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start, // 자식 위젯을 왼쪽 정렬합니다.
            children: [
              Text(
                event['eventName'], // 이벤트 이름을 표시합니다.
                style: TextStyle(fontSize: 18.0, fontWeight: FontWeight.bold), // 텍스트 스타일을 설정합니다.
              ),
              SizedBox(height: 8.0), // 위젯 간 간격을 설정합니다.
              Text(
                event['description'], // 이벤트 설명을 표시합니다.
                style: TextStyle(fontSize: 14.0), // 텍스트 스타일을 설정합니다.
              ),
            ],
          ),
        ),
      ),
    );
  }
}