import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:wooki/star/Schefuler/get_Schedul.dart'; // ScheduleService 클래스가 있는 파일 경로를 지정하세요.

class EditScheduleScreen extends StatefulWidget {
  final Map<String, dynamic> schedule;

  EditScheduleScreen({required this.schedule});

  @override
  _EditScheduleScreenState createState() => _EditScheduleScreenState();
}

class _EditScheduleScreenState extends State<EditScheduleScreen> {
  final _formKey = GlobalKey<FormState>();
  late String _title; // 일정 제목을 저장하는 변수
  late String _description; // 일정 설명을 저장하는 변수
  late DateTime _selectedDate; // 선택된 날짜를 저장하는 변수

  @override
  void initState() {
    super.initState();
    // 위젯 초기화 시에 스케줄 정보를 이용하여 필드 초기화
    _title = widget.schedule['title'];
    _description = widget.schedule['description'];
    _selectedDate = (widget.schedule['date'] as Timestamp)
        .toDate(); // Timestamp를 DateTime으로 변환
  }

  // 일정을 저장하는 메서드
  void _saveSchedule() {
    if (_formKey.currentState!.validate()) {
      _formKey.currentState!.save();
      // ScheduleService 클래스를 사용하여 데이터를 업데이트
      ScheduleService()
          .updateSchedule(widget.schedule['documentId'], _title, _description,
              _selectedDate)
          .then((_) {
        Navigator.pop(context); // 일정 수정 화면 닫기
      }).catchError((error) {
        // 오류 발생 시 처리
        print('Failed to update schedule: $error');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('일정 수정에 실패했습니다. 다시 시도해 주세요.')),
        );
      });
    }
  }

  // 날짜 선택 다이얼로그를 띄우는 메서드
  void _pickDate() async {
    DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2000),
      lastDate: DateTime(2101),
    );

    // 사용자가 날짜를 선택한 경우 상태를 업데이트하여 선택한 날짜를 반영
    if (pickedDate != null && pickedDate != _selectedDate) {
      setState(() {
        _selectedDate = pickedDate;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        // 아래 주석을 제거하고, 위의 title을 주석 처리하여 제목을 가운데 정렬하세요.
        // 여기서는 제목 위젯을 별도로 추가하고 가운데 정렬합니다.
        title: SizedBox(
          width: double.infinity, // 화면 전체 너비를 사용하여 가운데 정렬
          child: Text(
            '일정 수정', // 앱바 제목
            textAlign: TextAlign.center, // 가운데 정렬
          ),
        ),
        leading: IconButton(
          icon: Icon(Icons.arrow_back), // 뒤로가기 아이콘
          onPressed: () {
            Navigator.pop(context); // 뒤로가기 버튼 클릭 시 화면 닫기
          },
        ),
      ),
      body: Padding(
        padding: EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              TextFormField(
                initialValue: _title,
                decoration: InputDecoration(labelText: '제목'),
                onSaved: (value) {
                  _title = value!; // 입력된 제목을 저장
                },
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return '제목을 입력하세요'; // 제목이 비어있는 경우 에러 반환
                  }
                  return null; // 유효성 검사 통과
                },
              ),
              TextFormField(
                initialValue: _description,
                decoration: InputDecoration(labelText: '내용'),
                onSaved: (value) {
                  _description = value!; // 입력된 내용을 저장
                },
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return '내용을 입력하세요'; // 내용이 비어있는 경우 에러 반환
                  }
                  return null; // 유효성 검사 통과
                },
              ),
              SizedBox(height: 20), // 위젯 간 간격 설정
              Row(
                children: [
                  Text(
                    "선택된 날짜 : ${DateFormat('yyyy-MM-dd').format(_selectedDate)}",
                  ),
                  SizedBox(width: 20), // 위젯 간 간격 설정
                  ElevatedButton(
                    onPressed: _pickDate,
                    child: Text('날짜 선택'),
                  ),
                ],
              ),

              SizedBox(height: 20), // 위젯 간 간격 설정
              ElevatedButton(
                onPressed: _saveSchedule, // 저장 버튼 클릭 시 _saveSchedule 메서드 호출
                child: Text('저장'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
