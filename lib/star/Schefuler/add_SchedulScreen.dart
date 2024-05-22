import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

class AddScheduleScreen extends StatefulWidget {
  final DateTime selectedDate; // 이전 화면에서 전달된 선택된 날짜
  final Function(DateTime)
      updateScheduleCount; // HomeScreen 클래스에서 updateScheduleCount 메서드를 전달받음

  AddScheduleScreen(
      {required this.selectedDate, required this.updateScheduleCount});

  @override
  _AddScheduleScreenState createState() =>
      _AddScheduleScreenState(selectedDate: selectedDate);
}

class _AddScheduleScreenState extends State<AddScheduleScreen> {
  final _formKey = GlobalKey<FormState>(); // 폼 상태를 관리하기 위한 GlobalKey
  bool isHomeSwitched = false; // 스위치의 초기 상태는 꺼진 상태
  bool isdaySwitched = false;
  bool _isYearlyRepeat = false;
  late TextEditingController _titleController; // 일정 제목 입력 필드 컨트롤러
  late TextEditingController _descriptionController; // 일정 설명 입력 필드 컨트롤러
  late DateTime _selectedDate; // 선택된 날짜, 초기값은 현재 날짜로 설정
  String _selectedType = '기념일'; // 초기 기념일 유형

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
          'type': _selectedType,
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Schedule added successfully')), // 성공 메시지 표시
        );
        // 저장 후에 화면을 닫고 홈 화면으로 돌아가서 스케줄 목록을 업데이트합니다.
        Navigator.pop(context);
        widget.updateScheduleCount(_selectedDate);
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
        leading: TextButton(
          onPressed: () {
            Navigator.pop(context); // 화면 되돌아가기
          },
          child: Text(
            '취소',
            style: TextStyle(
              fontSize: 18,
              color: Colors.blueAccent, // 텍스트 색상 설정
              fontWeight: FontWeight.bold, // 텍스트 굵게 설정
            ),
          ),
          style: TextButton.styleFrom(
            padding: EdgeInsets.symmetric(horizontal: 10.0),
          ),
        ),
        title: Text('기념일'), // 화면 제목 표시
        centerTitle: true, // 중앙 정렬
        actions: [
          TextButton(
            onPressed: _saveSchedule, // 일정 저장 버튼 클릭 시 저장 메서드 호출
            child: Text(
              '저장',
              style: TextStyle(
                fontSize: 18,
                color: Colors.blueAccent, // 텍스트 색상 설정
                fontWeight: FontWeight.bold, // 텍스트 굵게 설정
              ),
            ),
            style: TextButton.styleFrom(
              padding: EdgeInsets.symmetric(horizontal: 10.0),
            ),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                color: Colors.blueGrey[50], // 배경 색상 설정
                height: 50.0, // 높이 설정
                width: double.infinity,
                padding: EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
              ),
              SizedBox(height: 16), // 위젯 간 간격 설정
              TextFormField(
                controller: _titleController, // 컨트롤러 연결
                decoration: InputDecoration(
                  labelText: '제목',
                  labelStyle: TextStyle(color: Colors.blueGrey[700]),
                  // 입력 필드 레이블 색상 설정
                  border: OutlineInputBorder(),
                ), // 입력 필드 레이블 설정
                validator: (value) {
                  if (value!.isEmpty) {
                    return '제목을 입력해 주세요'; // 제목이 입력되지 않은 경우 에러 메시지 반환
                  }
                  return null; // 유효성 검사 통과
                },
                onSaved: (value) {
                  // 입력된 제목을 저장하거나 처리할 때 사용됩니다.
                },
              ),
              SizedBox(height: 16),
              DropdownButtonFormField<String>(
                value: _selectedType,
                decoration: InputDecoration(
                  labelText: '기념일 유형',
                  labelStyle: TextStyle(color: Colors.blueGrey[700]),
                  // 입력 필드 레이블 색상 설정
                  border: OutlineInputBorder(),
                ),
                items: <String>[
                  '기념일',
                  '생일',
                  '연애 시작일',
                  '결혼 기념일',
                  '첫 만남 기념일',
                  '첫 데이트 기념일',
                  '프로포즈 기념일',
                  '졸업 기념일',
                  '입학 기념일',
                  '취업 기념일',
                  '특별한 날',
                  '휴가 시작일',
                  '이사 기념일',
                  '기타 기념일'
                ].map<DropdownMenuItem<String>>((String value) {
                  return DropdownMenuItem<String>(
                    value: value,
                    child: Text(value),
                  );
                }).toList(),
                onChanged: (String? newValue) {
                  setState(() {
                    _selectedType = newValue!;
                  });
                },
              ),
              SizedBox(height: 16),
              Container(
                color: Colors.blueGrey[50], // 배경 색상 설정
                height: 50.0, // 높이 설정
                width: double.infinity,
                padding: EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
              ),
              SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                // 수평 방향으로 위젯을 양 끝에 배치
                children: [
                  Text(
                    '홈화면 표시', // 표시할 텍스트
                    style: TextStyle(fontSize: 16),
                  ),
                  Switch(
                    value: isHomeSwitched, // 스위치의 상태를 isSwitched 변수로 설정
                    onChanged: (value) {
                      setState(() {
                        isHomeSwitched = value; // 스위치 상태 변경
                        // 여기에 스위치가 켜졌을 때 또는 꺼졌을 때 실행할 로직을 추가할 수 있습니다.
                      });
                    },
                  ),
                ],
              ),
              Container(
                color: Colors.blueGrey[50], // 배경 색상 설정
                height: 50.0, // 높이 설정
                width: double.infinity,
                padding: EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
              ),
              SizedBox(height: 16), // 위젯 간 간격 설정
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                // 수평 방향으로 위젯을 양 끝에 배치
                children: [
                  Text(
                    "선택된 날짜 : ${DateFormat('yyyy-MM-dd').format(_selectedDate)}",
                    style: TextStyle(fontSize: 16, color: Colors.blueGrey[700]),
                    textAlign: TextAlign.center,
                  ), // 선택된 날짜 텍스트 표시
                  ElevatedButton(
                    onPressed: () => _selectDate(context), // 버튼 클릭 시 날짜 선택
                    child: Text('날짜 선택'), // 버튼 텍스트 설정
                  ),
                ],
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    "설정일을 1일로 세기",
                    style: TextStyle(fontSize: 16),
                  ),
                  Switch(
                    value: isdaySwitched,
                    onChanged: (value) {
                      setState(() {
                        isdaySwitched = value;
                      });
                    },
                  )
                ],
              ),
              SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    "반복(매년)",
                    style: TextStyle(fontSize: 16),
                  ),
                  Switch(
                    value: _isYearlyRepeat,
                    onChanged: (value) {
                      setState(() {
                        _isYearlyRepeat = value;
                      });
                    },
                  )
                ],
              ),
              SizedBox(height: 16),
              Container(
                color: Colors.blueGrey[50], // 배경 색상 설정
                height: 50.0, // 높이 설정
                width: double.infinity,
                padding: EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
              ),
              SizedBox(height: 16),

              TextFormField(
                controller: _descriptionController,
                decoration: InputDecoration(
                  labelText: '내용',
                  labelStyle: TextStyle(color: Colors.blueGrey[700]),
                  // 입력 필드 레이블 색상 설정
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value!.isEmpty) {
                    return '내용을 입력해 주세요'; // 설명이 입력되지 않은 경우 에러 메시지 반환
                  }
                  return null; // 유효성 검사 통과
                },
                onSaved: (value) {
                  // 입력된 설명을 저장하거나 처리할 때 사용됩니다.
                },
                keyboardType: TextInputType.multiline,
                maxLines: null, // 최대 줄 수를 제한하지 않음
              ),
            ],
          ),
        ),
      ),
    );
  }
}
