import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

class AddScheduleScreen extends StatefulWidget {
  final DateTime selectedDate; // 이전 화면에서 전달된 선택된 날짜

  AddScheduleScreen({required this.selectedDate});

  @override
  _AddScheduleScreenState createState() => _AddScheduleScreenState(selectedDate: selectedDate);
}

class _AddScheduleScreenState extends State<AddScheduleScreen> {
  final _formKey = GlobalKey<FormState>(); // 폼 상태를 관리하기 위한 GlobalKey

  late TextEditingController _titleController; // 일정 제목 입력 필드 컨트롤러
  late TextEditingController _descriptionController; // 일정 설명 입력 필드 컨트롤러
  late DateTime _selectedDate; // 선택된 날짜, 초기값은 현재 날짜로 설정

  _AddScheduleScreenState({required DateTime selectedDate}) {
    _selectedDate = selectedDate;
  }

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController();
    _descriptionController = TextEditingController();
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _saveSchedule() async {
    if (_formKey.currentState!.validate()) {
      // 폼 유효성 검사
      _formKey.currentState!.save(); // 폼 저장

      try {
        // Firestore에 'schedules' 컬렉션에 일정 추가
        await FirebaseFirestore.instance.collection('schedules').add({
          'title': _titleController.text,
          'description': _descriptionController.text,
          'date': _selectedDate,
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Schedule added successfully')), // 성공 메시지 표시
        );
        Navigator.pop(context); // 화면 되돌아가기
      } catch (e) {
        print(e); // 에러가 발생한 경우 콘솔에 에러 로그 출력
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to add schedule')), // 실패 메시지 표시
        );
      }
    }
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate, // 초기 선택 날짜 설정
      firstDate: DateTime(2000), // 선택 가능한 가장 이른 날짜
      lastDate: DateTime(2101), // 선택 가능한 가장 늦은 날짜
    );

    // 사용자가 날짜를 선택한 경우 상태를 업데이트하여 선택한 날짜를 반영합니다.
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('일정 추가하기'), // 화면 제목 표시
        leading: IconButton(
          icon: Icon(Icons.arrow_back), // 뒤로가기 아이콘
          onPressed: () {
            Navigator.pop(context); // 화면 되돌아가기
          },
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextFormField(
                controller: _titleController, // 컨트롤러 연결
                decoration: InputDecoration(labelText: '제목'), // 입력 필드 레이블 설정
                validator: (value) {
                  if (value!.isEmpty) {
                    return 'Please enter a title'; // 제목이 입력되지 않은 경우 에러 메시지 반환
                  }
                  return null; // 유효성 검사 통과
                },
                onSaved: (value) {
                  // 입력된 제목을 저장하거나 처리할 때 사용됩니다.
                },
              ),
              TextFormField(
                controller: _descriptionController,
                // 컨트롤러 연결
                decoration: InputDecoration(labelText: '내용'),
                // 입력 필드 레이블 설정
                validator: (value) {
                  if (value!.isEmpty) {
                    return 'Please enter a description'; // 설명이 입력되지 않은 경우 에러 메시지 반환
                  }
                  return null; // 유효성 검사 통과
                },
                onSaved: (value) {
                  // 입력된 설명을 저장하거나 처리할 때 사용됩니다.
                },
                keyboardType: TextInputType.multiline,
                // 여러 줄 입력 가능하도록 설정
                maxLines: null, // 최대 줄 수를 제한하지 않음
              ),
              SizedBox(height: 16), // 위젯 간 간격 설정
              Row(
                children: [
                  Text(
                    "선택된 날짜 : ${DateFormat('yyyy-MM-dd').format(_selectedDate)}",
                  ), // 선택된 날짜 텍스트 표시
                  SizedBox(width: 16), // 위젯 간 간격 설정
                  ElevatedButton(
                    onPressed: () => _selectDate(context), // 버튼 클릭 시 날짜 선택
                    child: Text('날짜 선택'), // 버튼 텍스트 설정
                  ),
                ],
              ),
              SizedBox(height: 16), // 위젯 간 간격 설정
              ElevatedButton(
                onPressed: _saveSchedule, // 일정 저장 버튼 클릭 시 저장 메서드 호출
                child: Text('저장'), // 버튼 텍스트 설정
              ),
            ],
          ),
        ),
      ),
    );
  }
}
