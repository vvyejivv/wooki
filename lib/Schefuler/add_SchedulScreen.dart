import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'get_Schedule.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AddScheduleScreen extends StatefulWidget {
  final DateTime selectedDate; // 이전 화면에서 전달된 선택된 날짜
  final Function(DateTime) updateScheduleCount; // HomeScreen 클래스에서 updateScheduleCount 메서드를 전달받음

  AddScheduleScreen({required this.selectedDate, required this.updateScheduleCount});

  @override
  _AddScheduleScreenState createState() => _AddScheduleScreenState(selectedDate: selectedDate);
}

class _AddScheduleScreenState extends State<AddScheduleScreen> {
  final _formKey = GlobalKey<FormState>(); // 폼 상태를 관리하기 위한 글로벌 키
  bool isHomeSwitched = false; // 홈화면 표시 스위치 상태
  bool isdaySwitched = false; // 설정일을 1일로 세기 스위치 상태
  bool _isYearlyRepeat = false; // 매년 반복 스위치 상태
  late TextEditingController _titleController; // 일정 제목 입력 필드 컨트롤러
  late TextEditingController _descriptionController; // 일정 설명 입력 필드 컨트롤러
  late DateTime _selectedDate; // 선택된 날짜
  String _selectedType = '기념일'; // 초기 기념일 유형
  String? _email; // 세션 이메일

  _AddScheduleScreenState({required DateTime selectedDate}) {
    _selectedDate = selectedDate; // 초기 선택된 날짜 설정
  }

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(); // 제목 입력 필드 컨트롤러 초기화
    _descriptionController = TextEditingController(); // 설명 입력 필드 컨트롤러 초기화
    _loadEmail(); // 이메일 로드
  }

  Future<void> _loadEmail() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _email = prefs.getString('email'); // 이메일 값 로드
    });
  }

  @override
  void dispose() {
    _titleController.dispose(); // 제목 입력 필드 컨트롤러 해제
    _descriptionController.dispose(); // 설명 입력 필드 컨트롤러 해제
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
        _selectedDate = picked; // 선택된 날짜를 상태에 반영
      });
    }
  }

  // 일정 저장 메서드
  void _saveSchedule(BuildContext context) {
    if (_email == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('이메일을 불러오지 못했습니다. 다시 시도해주세요.')),
      );
      return;
    }

    ScheduleService().saveSchedule(
      context,
      _formKey,
      _titleController,
      _descriptionController,
      _selectedDate,
      _selectedType,
          (date) => widget.updateScheduleCount(date),
      _email!, // 세션 이메일 전달
    );
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
                color: Colors.blueAccent,
                fontWeight: FontWeight.bold,
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
              onPressed: () => _saveSchedule(context),
              // 저장 버튼 클릭 시 일정 저장 메서드 호출
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
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    color: Colors.blueGrey[50], // 배경 색상 설정
                    height: 50.0, // 높이 설정
                    width: double.infinity, // 너비 설정
                    padding:
                    EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
                  ),
                  SizedBox(height: 16), // 위젯 간 간격 설정
                  TextFormField(
                    controller: _titleController, // 컨트롤러 연결
                    decoration: InputDecoration(
                      labelText: '제목',
                      // 입력 필드 레이블 설정
                      labelStyle: TextStyle(color: Colors.blueGrey[700]),
                      // 레이블 색상 설정
                      border: OutlineInputBorder(),
                    ),
                    validator: (value) {
                      if (value!.isEmpty) {
                        return '제목을 입력해 주세요'; // 제목이 입력되지 않은 경우 에러 메시지 반환
                      }
                      return null; // 유효성 검사 통과
                    },
                    onSaved: (value) {},
                  ),
                  SizedBox(height: 16),
                  DropdownButtonFormField<String>(
                    value: _selectedType, // 초기 선택된 기념일 유형
                    decoration: InputDecoration(
                      labelText: '기념일 유형',
                      // 입력 필드 레이블 설정
                      labelStyle: TextStyle(color: Colors.blueGrey[700]),
                      // 레이블 색상 설정
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
                        _selectedType = newValue!; // 새로운 기념일 유형 선택 시 상태 업데이트
                      });
                    },
                  ),
                  SizedBox(height: 16),
                  Container(
                    color: Colors.blueGrey[50], // 배경 색상 설정
                    height: 50.0, // 높이 설정
                    width: double.infinity, // 너비 설정
                    padding:
                    EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
                  ),
                  SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        '홈화면 표시', // 표시할 텍스트
                        style: TextStyle(fontSize: 16),
                      ),
                      Switch(
                        value: isHomeSwitched, // 스위치의 상태를 isHomeSwitched 변수로 설정
                        onChanged: (value) {
                          setState(() {
                            isHomeSwitched = value; // 스위치 상태 변경
                          });
                        },
                      ),
                    ],
                  ),
                  Container(
                    color: Colors.blueGrey[50], // 배경 색상 설정
                    height: 50.0, // 높이 설정
                    width: double.infinity, // 너비 설정
                    padding:
                    EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
                  ),
                  SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        "선택된 날짜 : ${DateFormat('yyyy-MM-dd').format(_selectedDate)}",
                        style: TextStyle(
                            fontSize: 16, color: Colors.blueGrey[700]),
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
                    width: double.infinity, // 너비 설정
                    padding:
                    EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
                  ),
                  SizedBox(height: 16),
                  TextFormField(
                    controller: _descriptionController,
                    decoration: InputDecoration(
                      labelText: '내용',
                      // 입력 필드 레이블 설정
                      labelStyle: TextStyle(color: Colors.blueGrey[700]),
                      // 레이블 색상 설정
                      border: OutlineInputBorder(),
                    ),
                    validator: (value) {
                      if (value!.isEmpty) {
                        return '내용을 입력해 주세요'; // 내용이 입력되지 않은 경우 에러 메시지 반환
                      }
                      return null;
                    },
                    onSaved: (value) {},
                    keyboardType: TextInputType.multiline,
                    maxLines: null, // 최대 줄 수를 제한하지 않음
                  ),
                ],
              ),
            ),
          ),
        ));
  }
}
