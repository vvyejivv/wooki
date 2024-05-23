import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';

void main() {
  runApp(Scheduler());
}

class Scheduler extends StatelessWidget {
  const Scheduler({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(
          title: Text('일정관리'), // 앱 바의 제목
          leading: IconButton(
            icon: Icon(Icons.arrow_back), // 뒤로 가기 아이콘
            onPressed: () {
              Navigator.pop(context); // 뒤로 가기 기능
            },
          ),
          actions: [
            // 앱 바의 오른쪽 영역
            IconButton(
              icon: Icon(Icons.search), // 검색 아이콘
              onPressed: () {
                // 검색 기능 구현
              },
            ),
          ],
          centerTitle: true, // 제목을 중앙에 배치
        ),
        body: TableCalendar(
          focusedDay: DateTime.now(), // 현재 날짜로 설정하거나 원하는 날짜를 설정하세요
          firstDay: DateTime(1800, 1, 1), // 달력의 처음 날짜
          lastDay: DateTime(3000, 1, 1), // 달력의 마지막 날짜
          headerStyle: HeaderStyle(
            titleCentered: true, // 제목 중앙에 위치하기
            formatButtonVisible: false, // 달력 크기 선택 옵션 없애기
            // 달력 제목 스타일
            titleTextStyle: TextStyle(
              fontWeight: FontWeight.bold, // 두껍게 설정
              fontSize: 20.0, // 폰트 크기 설정
              // color: Colors.black, // 적절한 색상 설정
            ),
          ),
          calendarStyle: CalendarStyle(
            isTodayHighlighted: true,
            defaultDecoration: BoxDecoration(
              // 평일 배경색을 Color 객체로 지정
              borderRadius: BorderRadius.circular(6.0),
              // color: Colors.white, // 적절한 배경 색상 설정
            ),
            weekendDecoration: BoxDecoration(
              // 주말 배경색을 Color 객체로 지정
              borderRadius: BorderRadius.circular(6.0),
              // color: Colors.white, // 적절한 배경 색상 설정
            ),
            selectedDecoration: BoxDecoration(
              // 선택된 날짜 스타일
              borderRadius: BorderRadius.circular(6.0),
              border: Border.all(
                // 테두리 스타일
                // color: Colors.yellow.withOpacity(0.5), // 적절한 색상 설정
                width: 1.0,
              ),
            ),
            defaultTextStyle: TextStyle(
              // 기본 글꼴
              fontWeight: FontWeight.w600,
              // color: Colors.black, // 적절한 글꼴 색상 설정
            ),
            weekendTextStyle: TextStyle(
              // 주말 글꼴
              fontWeight: FontWeight.w600,
              // color: Colors.black, // 적절한 글꼴 색상 설정
            ),
            selectedTextStyle: TextStyle(
              // 선택된 날짜 글꼴
              fontWeight: FontWeight.w600,
              // color: Colors.black, // 적절한 글꼴 색상 설정
            ),
          ),
        ),
      ),
    );
  }
}
