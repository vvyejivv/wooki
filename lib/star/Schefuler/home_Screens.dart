import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:wooki/star/Schefuler/main_calander.dart';
import 'package:wooki/star/Schefuler/add_SchedulScreen.dart';
import 'package:wooki/star/Schefuler/edit_SchedulScreen.dart';
import 'package:wooki/star/Schefuler/get_Schedul.dart'; // ScheduleService 클래스가 있는 파일 경로를 지정하세요.
import 'package:wooki/star/Schefuler/today_banner.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:wooki/star/Schefuler/delete_SchedulScreen.dart';
import '../firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  // Firebase 초기화 코드 추가
  initializeDateFormatting('ko_KR', null).then((_) {
    runApp(MyApp());
  });
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: '일정 관리',
      theme: ThemeData(),
      home: HomeScreen(),
    );
  }
}

class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  DateTime selectedDate = DateTime.utc(
    DateTime.now().year,
    DateTime.now().month,
    DateTime.now().day,
  );

  int scheduleCount = 0; // 일정 개수를 저장할 변수
  List<Map<String, dynamic>> schedules = []; // 일정 목록을 저장할 변수

  @override
  void initState() {
    super.initState();
    updateScheduleCount(selectedDate);
  }

  void onDaySelected(DateTime selectedDay, DateTime focusedDay) {
    setState(() {
      selectedDate = selectedDay;
      updateScheduleCount(selectedDate); // 날짜가 변경될 때마다 일정 개수 업데이트
    });
  }

  // 선택된 날짜에 해당하는 일정 개수를 가져와서 scheduleCount 변수에 저장하는 메서드
  void updateScheduleCount(DateTime selectedDate) {
    ScheduleService()
        .fetchSchedulesForDate(selectedDate)
        .then((fetchedSchedules) {
      setState(() {
        schedules = fetchedSchedules; // 일정 목록 업데이트
        scheduleCount = fetchedSchedules.length; // 일정 개수 업데이트
      });
    }).catchError((error) {
      print('일정 가져오기 실패: $error');
      // 에러 발생 시 일정 개수를 0으로 설정
      setState(() {
        schedules = []; // 일정 목록 초기화
        scheduleCount = 0;
      });
    });
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            // 메인 캘린더 위젯을 표시합니다.
            MainCalendar(
              selectedDate: selectedDate,
              onDaySelected: onDaySelected,
            ),
            // 오늘의 일정 개수를 나타내는 배너를 표시합니다.
            TodayBanner(
              selectedDate: selectedDate,
              count: scheduleCount, // 계산된 일정 개수를 전달
            ),
            Expanded(
              child: FutureBuilder<List<Map<String, dynamic>>>(
                future: ScheduleService().fetchSchedulesForDate(selectedDate),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    // 데이터를 불러오는 중이면 로딩 스피너를 표시합니다.
                    return Center(child: CircularProgressIndicator());
                  } else if (snapshot.hasError) {
                    // 에러가 발생하면 에러 메시지를 표시합니다.
                    return Center(child: Text('오류: ${snapshot.error}'));
                  } else {
                    // 데이터가 성공적으로 불러와졌을 때
                    schedules = snapshot.data!;
                    return ListView.builder(
                      itemCount: schedules.length,
                      itemBuilder: (context, index) {
                        return Card(
                          margin: EdgeInsets.all(8.0),
                          child: ListTile(
                            title: Row(
                              children: [
                                Text(
                                  '제목 : ',
                                  style: TextStyle(fontWeight: FontWeight.bold),
                                ),
                                Expanded(
                                  child: Text(
                                    '${schedules[index]['title']}',
                                    style:
                                        TextStyle(fontWeight: FontWeight.bold),
                                  ),
                                ),
                              ],
                            ),
                            subtitle: Row(
                              children: [
                                Text(
                                  '내용 : ',
                                  style: TextStyle(fontWeight: FontWeight.bold),
                                ),
                                Expanded(
                                  child: Text(
                                    '${schedules[index]['description']}',
                                  ),
                                ),
                              ],
                            ),
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                // 수정 아이콘을 누르면 해당 일정을 수정하는 화면으로 이동합니다.
                                IconButton(
                                  icon: Icon(Icons.edit),
                                  onPressed: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) =>
                                            EditScheduleScreen(
                                                schedule: schedules[index]),
                                      ),
                                    ).then((value) {
                                      if (value == true) {
                                        setState(() {
                                          updateScheduleCount(selectedDate);
                                        });
                                      }
                                    });
                                  },
                                ),
                                // 삭제 아이콘을 누르면 해당 일정을 삭제합니다.
                                IconButton(
                                  icon: Icon(Icons.delete),
                                  onPressed: () {
                                    // 삭제 기능을 구현합니다.
                                    deleteSchedule(context, selectedDate,
                                        schedules, index);

                                  },
                                ),
                              ],
                            ),
                            onTap: () {
                              // 일정을 탭하면 일정 상세 정보로 이동할 수 있는 기능 추가
                              //Navigator.push(context, MaterialPageRoute(builder: (context) => ScheduleDetailScreen(schedule: schedules[index])));
                            },
                          ),
                        );
                      },
                    );
                  }
                },
              ),
            ),
          ],
        ),
      ),
      // 일정 추가 버튼
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          // 일정 추가 화면으로 이동하고, 이후 일정을 추가한 후 돌아왔을 때 상태를 업데이트합니다.
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) =>
                  AddScheduleScreen(selectedDate: selectedDate),
            ),
          ).then((value) {
            if (value == true) {
              setState(() {
                updateScheduleCount(selectedDate);
              });
            }
          });
        },
        child: Icon(Icons.add),
      ),
    );
  }
}
