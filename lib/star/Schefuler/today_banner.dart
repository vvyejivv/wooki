import 'package:flutter/material.dart';

class TodayBanner extends StatelessWidget {
  final DateTime selectedDate; //선택된 날짜
  final int count; //일정 개수

  const TodayBanner({required this.selectedDate, required this.count, Key? key})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    final textStyle = TextStyle(
      fontWeight: FontWeight.w600,
      color: Colors.white,
    );

    return Container(
      color: Colors.blue,
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              '${selectedDate.year}년 ${selectedDate.month}월 ${selectedDate.day}일',
              style: textStyle,
            ),
            Text(
              '$count개',
              style: textStyle,
            ),
          ],
        ),
      ),
    );
  }
}
