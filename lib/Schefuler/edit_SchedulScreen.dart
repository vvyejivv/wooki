import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'get_Schedule.dart';

class EditScheduleScreen extends StatefulWidget {
  final Map<String, dynamic> schedule; // 기존 일정 데이터
  final void Function(DateTime selectedDate) updateScheduleCount; // 일정 개수를 업데이트하는 함수

  EditScheduleScreen({required this.schedule, required this.updateScheduleCount});

  @override
  _EditScheduleScreenState createState() => _EditScheduleScreenState();
}

class _EditScheduleScreenState extends State<EditScheduleScreen> {
  final _formKey = GlobalKey<FormState>(); // 폼 상태를 관리하기 위한 글로벌 키
  bool isHomeSwitched = false; // 홈 화면 표시 스위치 상태
  bool isdaySwitched = false; // 1일로 세기 스위치 상태
  bool _isYearlyRepeat = false; // 매년 반복 스위치 상태
  late TextEditingController _titleController; // 일정 제목 입력 컨트롤러
  late TextEditingController _descriptionController; // 일정 설명 입력 컨트롤러
  late DateTime _selectedDate; // 선택된 날짜
  String _selectedType = '기념일'; // 선택된 기념일 유형

  @override
  void initState() {
    super.initState();
    // 일정 데이터로부터 초기 값을 설정합니다.
    _titleController = TextEditingController(text: widget.schedule['title'] ?? '');
    _descriptionController = TextEditingController(text: widget.schedule['description'] ?? '');
    _selectedType = widget.schedule['type'] ?? '기념일';
    _selectedDate = (widget.schedule['date'] as Timestamp?)?.toDate() ?? DateTime.now();
  }

  @override
  void dispose() {
    // 컨트롤러를 해제하여 메모리 누수를 방지합니다.
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  // 날짜 선택 다이얼로그를 보여줍니다.
  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2000),
      lastDate: DateTime(2101),
    );

    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  // 일정 저장 메서드
  void _saveSchedule(BuildContext context) {
    if (_formKey.currentState!.validate()) {
      _formKey.currentState!.save();
      // Firestore에 일정을 수정합니다.
      ScheduleService().editSchedule(
        widget.schedule['documentId'],
        _titleController.text,
        _descriptionController.text,
        _selectedDate,
        _selectedType,
      ).then((_) {
        // 일정 개수를 업데이트하고 화면을 닫습니다.
        widget.updateScheduleCount(_selectedDate);
        Navigator.pop(context, true);
      }).catchError((error) {
        print('Failed to update schedule: $error');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('일정 수정에 실패했습니다. 다시 시도해 주세요.')),
        );
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: TextButton(
          onPressed: () {
            Navigator.pop(context);
          },
          child: Text(
            '취소',
            style: TextStyle(
              fontSize: 18,
              color: Colors.blueAccent,
              fontWeight: FontWeight.bold,
            ),
          ),
          style: TextButton.styleFrom(
            padding: EdgeInsets.symmetric(horizontal: 10.0),
          ),
        ),
        title: Text('일정 수정'),
        centerTitle: true,
        actions: [
          TextButton(
            onPressed: () => _saveSchedule(context),
            child: Text(
              '저장',
              style: TextStyle(
                fontSize: 18,
                color: Colors.blueAccent,
                fontWeight: FontWeight.bold,
              ),
            ),
            style: TextButton.styleFrom(
              padding: EdgeInsets.symmetric(horizontal: 10.0),
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                color: Colors.blueGrey[50],
                height: 50.0,
                width: double.infinity,
                padding: EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
              ),
              SizedBox(height: 16),
              TextFormField(
                controller: _titleController,
                decoration: InputDecoration(
                  labelText: '제목',
                  labelStyle: TextStyle(color: Colors.blueGrey[700]),
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value!.isEmpty) {
                    return '제목을 입력해 주세요';
                  }
                  return null;
                },
                onSaved: (value) {},
              ),
              SizedBox(height: 16),
              DropdownButtonFormField<String>(
                value: _selectedType,
                decoration: InputDecoration(
                  labelText: '기념일 유형',
                  labelStyle: TextStyle(color: Colors.blueGrey[700]),
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
                color: Colors.blueGrey[50],
                height: 50.0,
                width: double.infinity,
                padding: EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
              ),
              SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '홈화면 표시',
                    style: TextStyle(fontSize: 16),
                  ),
                  Switch(
                    value: isHomeSwitched,
                    onChanged: (value) {
                      setState(() {
                        isHomeSwitched = value;
                      });
                    },
                  ),
                ],
              ),
              Container(
                color: Colors.blueGrey[50],
                height: 50.0,
                width: double.infinity,
                padding: EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
              ),
              SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    "선택된 날짜 : ${DateFormat('yyyy-MM-dd').format(_selectedDate)}",
                    style: TextStyle(fontSize: 16, color: Colors.blueGrey[700]),
                    textAlign: TextAlign.center,
                  ),
                  ElevatedButton(
                    onPressed: () => _selectDate(context),
                    child: Text('날짜 선택'),
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
                color: Colors.blueGrey[50],
                height: 50.0,
                width: double.infinity,
                padding: EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
              ),
              SizedBox(height: 16),
              TextFormField(
                controller: _descriptionController,
                decoration: InputDecoration(
                  labelText: '내용',
                  labelStyle: TextStyle(color: Colors.blueGrey[700]),
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value!.isEmpty) {
                    return '내용을 입력해 주세요';
                  }
                  return null;
                },
                onSaved: (value) {},
                keyboardType: TextInputType.multiline,
                maxLines: null,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
