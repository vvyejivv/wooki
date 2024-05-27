import 'package:flutter/material.dart';

class MessageTile extends StatelessWidget {
  final dynamic message;
  final bool? isAdmin; // 관리자 메시지 여부

  const MessageTile({Key? key, required this.message, this.isAdmin}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final bool? isConfirmed = message['confirmed'] as bool?;

    return Container(
      margin: EdgeInsets.symmetric(vertical: 4),
      padding: EdgeInsets.all(12),
      decoration: BoxDecoration(
        // 관리자 메시지인 경우 파란색 배경, 사용자 메시지인 경우 회색 배경 설정
        color: isAdmin ?? false ? Colors.blue[100] : Colors.grey[300],
        // 모서리를 둥글게 설정하여 시각적으로 구분
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(isAdmin ?? false ? 0 : 16),
          topRight: Radius.circular(isAdmin ?? false ? 16 : 0),
          bottomLeft: Radius.circular(16),
          bottomRight: Radius.circular(16),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            message['text'],
            style: TextStyle(
              fontSize: 16,
              // 관리자 메시지인 경우 텍스트를 굵게 표시하여 시각적으로 강조
              fontWeight: isAdmin ?? false ? FontWeight.bold : FontWeight.normal,
              // 관리자 메시지인 경우 텍스트 색상을 흰색으로 설정
              color: isAdmin ?? false ? Colors.white : Colors.black,
            ),
          ),
          SizedBox(height: 8),
          if (isConfirmed == true) // 확인된 메시지인 경우 UI를 추가하여 표시
            Text(
              '확인됨',
              style: TextStyle(
                color: Colors.green,
                fontStyle: FontStyle.italic,
              ),
            ),
        ],
      ),
    );
  }
}
