import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';

class MainCalendar extends StatelessWidget {
  final void Function(DateTime, DateTime) onDaySelected; // 날짜 선택 시 실행할 콜백 함수
  final DateTime selectedDate; // 선택된 날짜

  MainCalendar({
    required this.onDaySelected,
    required this.selectedDate,
  });

  @override
  Widget build(BuildContext context) {
    return TableCalendar(
      onDaySelected: onDaySelected,
      // 날짜 선택 시 실행할 함수

      selectedDayPredicate: (date) => // 선택할 날짜를 구분할 조건
          date.year == selectedDate.year &&
          date.month == selectedDate.month &&
          date.day == selectedDate.day,

      focusedDay: DateTime.now(),
      // 현재 달력 위치
      firstDay: DateTime(1800),
      // 달력의 처음 날짜
      lastDay: DateTime(3000),
      // 달력의 마지막 날짜
      headerStyle: HeaderStyle(
        titleCentered: true, // 제목 중앙에 위치하기
        formatButtonVisible: false, // 달력 크기 선택 옵션 없애기
        titleTextStyle: TextStyle(
          fontWeight: FontWeight.w700,
          fontSize: 16.0,
        ),
      ),
      calendarStyle: CalendarStyle(
        isTodayHighlighted: true,
        // 오늘 날짜 강조 표시
        defaultDecoration: BoxDecoration(
          // 기본 날짜 스타일
          // borderRadius: BorderRadius.circular(6.0), // borderRadius 제거 또는 주석 처리
          color: Color.fromRGBO(255, 255, 255, 1),
          shape: BoxShape.rectangle, // 명확하게 직사각형 설정
        ),
        weekendDecoration: BoxDecoration(
          // 주말 날짜 스타일
          // borderRadius: BorderRadius.circular(6.0), // borderRadius 제거 또는 주석 처리
          color: Color.fromRGBO(255, 255, 255, 1),
          shape: BoxShape.rectangle, // 명확하게 직사각형 설정
        ),
        selectedDecoration: BoxDecoration(
          // 선택된 날짜 스타일
          borderRadius: BorderRadius.circular(6.0),
          border: Border.all(
            color: Colors.blue,
            width: 1.0,
          ),
          shape: BoxShape.rectangle, // 명확하게 직사각형 설정
        ),
        defaultTextStyle: TextStyle(
          // 기본 글꼴
          fontWeight: FontWeight.w600,
          color: Colors.black,
        ),
        weekendTextStyle: TextStyle(
          // 주말 글꼴
          fontWeight: FontWeight.w600,
          color: Colors.red,
        ),
        selectedTextStyle: TextStyle(
          // 선택된 날짜 글꼴
          fontWeight: FontWeight.w600,
          color: Colors.lightGreen,
        ),
      ),
      //한국어로 변경
      //locale: 'ko_KR',
    );
  }
}
